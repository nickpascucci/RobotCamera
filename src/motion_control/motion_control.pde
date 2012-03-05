/* -*- mode: c++; fill-column: 100; -*- */
/*
  Simplified motion control Arduino sketch for the robot's servomotors. 

  Commands:
  'b': Reverse move for 1 second.
  'f': Forward move for 1 second.
  'r': Right (clockwise) rotation of ~30 degrees.
  'l': Left (counter-clockwise) rotation of ~30 degrees.
*/

#include <Servo.h>
#include <Streaming.h>
#include "EServo.h"

EncodedServo left_servo;
EncodedServo right_servo;

// Encoder ticks per revolution
const int ticks_per_rev = 20;

// Move time in milliseconds for forward/backward movements
const int mseconds_per_move = 3000;

// Axle speed in RPM for all moves
const int cruise_speed = 18;

// These units don't really matter, as long as they're the same. I used inches.
// Body width, measured from centerline to centerline on the wheels.
const float body_width = 6.5;

// Wheel circumference.
const float wheel_circumference = 2.9;

// ## Movement

void move(bool forward){
  if(forward){
    Serial << "Moving forward." << endl;
    reset_ticks();
    right_servo.servo.write(right_servo.forward_point);
    left_servo.servo.write(left_servo.forward_point);

    // Wait for the move to complete
    delay(mseconds_per_move);

    stop();
    // At some point it will be desirable to reconcile both sides and make sure they've moved the
    // same distance. For right now, it's fine that they don't.
    // reconcile_servos(true);
  } else {
    Serial << "Moving backward." << endl;
    left_servo.ticks = 0;
    right_servo.ticks = 0;
    right_servo.servo.write(right_servo.backward_point);
    left_servo.servo.write(left_servo.backward_point);

    // Wait for the move to complete
    delay(mseconds_per_move);

    stop();
  }
  Serial << "Done." << endl;
}

/**
   Bring the servos to agreement, so their number of ticks is equal.
*/
void reconcile_servos(bool forward){
  while(left_servo.ticks > right_servo.ticks){
    // Left servo has moved farther, so fix the left and move the right
    left_servo.servo.write(left_servo.zero_point);
    if(forward) {
      right_servo.servo.write(right_servo.forward_point);
    } else {
      right_servo.servo.write(right_servo.backward_point);
    }
  } 
  stop();
  while (right_servo.ticks > left_servo.ticks) {
    right_servo.servo.write(right_servo.zero_point);
    if(forward) {
      left_servo.servo.write(left_servo.forward_point);
    } else {
      left_servo.servo.write(left_servo.backward_point);
    }
  }
  stop();
  Serial << "Done." << endl;
}

void rotate(bool clockwise){
  // We'll need to know how many ticks to move, so get that first.
  int required_ticks = angle_to_ticks(PI/6);
  // Reset the tick counters; we'll need them to keep track of our current position.
  reset_ticks(); 

  if(clockwise){
    Serial << "Rotating clockwise." << endl;

    // To rotate clockwise, we need to move the right servo backward and the left servo forward.
    left_servo.servo.write(left_servo.forward_point);
    right_servo.servo.write(right_servo.backward_point);

    // We need to keep an eye on both servos at the same time, so while one of them is short, 
    // keep updating.
    while(left_servo.ticks < required_ticks || right_servo.ticks < required_ticks){
      // Once we've reached our goal, stop the servo.
      if(left_servo.ticks >= required_ticks){
        left_servo.servo.write(left_servo.zero_point);
      }
      if(right_servo.ticks >= required_ticks){
        right_servo.servo.write(right_servo.zero_point);
      }
    }
  } else {
    Serial << "Rotating counter-clockwise." << endl;
    // Clockwise is the opposite.
    left_servo.servo.write(left_servo.backward_point);
    right_servo.servo.write(right_servo.forward_point);

    // We need to keep an eye on both servos at the same time, so while one of them is short, 
    // keep updating.
    while(left_servo.ticks < required_ticks || right_servo.ticks < required_ticks){
      // Once we've reached our goal, stop the servo.
      if(left_servo.ticks >= required_ticks){
        left_servo.servo.write(left_servo.zero_point);
      }
      if(right_servo.ticks >= required_ticks){
        right_servo.servo.write(right_servo.zero_point);
      }
    }
  }
  // Can't hurt to make sure we're stopped.
  stop();
  Serial << "Done." << endl;
}

/**
   Calculate the number of ticks required in order to rotate through the given angle.

   Since this is calculated with the center of rotation located equidistant between wheels on their
   shared axis, both wheels must move this number of ticks in order to complete the rotation.

   Angle should be in radians.
 */
int angle_to_ticks(float angle){
  // Remember, circumference = 2 * PI * radius; sector length = angle * radius; and we're working
  // with two circles here, the wheel and the circle that it's traveling on.
  // So, we first calculate the length of the sector we have to traverse. In this case, r is the
  // body width divided by two.
  float sec_length = angle * (body_width / 2);
  // Then we need to get the distance covered by the wheels between each tick.
  float distance_per_tick = wheel_circumference / ticks_per_rev;
  // Finally, we can divide the one by the other to get the number of ticks required.
  // This is going to have some rounding error; but it's going to be small enough that we can ignore
  // it for now. If you really want to know how much it is, it's easy to calculate.
  int num_ticks = sec_length / distance_per_tick;
  return num_ticks;
}

/**
   Stop both servos.
*/
void stop(){
  left_servo.servo.write(left_servo.zero_point);
  right_servo.servo.write(right_servo.zero_point);
}

void reset_ticks(){
    left_servo.ticks = 0;
    right_servo.ticks = 0;
}

/**
   Attach the appropriate interrupts to catch ticks from our encoders.
*/
void attach_encoder_interrupts(){
  attachInterrupt(right_servo.encoder_interrupt, right_encoder_tick, HIGH);
  attachInterrupt(left_servo.encoder_interrupt, left_encoder_tick, HIGH);
}

/**
   Record a right encoder tick.
*/
void right_encoder_tick(){
  right_servo.ticks++;
  toggle(13);
}

/**
   Record a left encoder tick.
*/
void left_encoder_tick(){
  left_servo.ticks++;
  toggle(13);
}

// ## Calibration
// These two variables will be modified in interrupt contexts, so they need to be declared volatile.
volatile int speed_calibration = 0;
volatile long int last_calibration_tick;

/**
   Find the point at which the servos move at a given speed.
*/
int calibrate_servo_speed(EncodedServo target_servo, long speed, float error, bool forward){
  // Start the servo at the given speed. This allows us to go both ways when calibrating, in order
  // to calibrate both sides' servos.
  if(forward){
    speed_calibration = 180;
  } else {
    speed_calibration = 0;
  }
  noInterrupts();
  target_servo.servo.write(speed_calibration);

  // Attach a calibration interrupt which decreases speed every time the encoder ticks
  detachInterrupt(target_servo.encoder_interrupt);
  if(forward){
    attachInterrupt(target_servo.encoder_interrupt, calibration_isr_dec, RISING);
  } else {
    attachInterrupt(target_servo.encoder_interrupt, calibration_isr_inc, RISING);
  }
  last_calibration_tick = millis();

  interrupts();

  // Wait for the speed to be reached, within acceptable error.
  while(abs(interval_to_speed(millis() - last_calibration_tick) - speed) > error){
    target_servo.servo.write(speed_calibration);
  };

  // Clean up by detaching interrupts:
  detachInterrupt(target_servo.encoder_interrupt);

  // Remember to reattach the interrupt, since we can't do it generally here.
  return speed_calibration;
}

/**
   Calculate the current rotation speed in rpm from an encoder tick interval
*/
inline float interval_to_speed(long interval){
  // Rotations per second = (ticks/second) / (ticks/rev)
  float tpm = 60000.0 / interval;
  return tpm / ticks_per_rev;
}

/**
   Calibrate both servos, for all of their control points.
*/
void calibrate_all(){
  Serial << "Calibrating..." << endl;
  // Bringing these parameters down will make the calibration take longer, but will detect smaller
  // errors. Keep in mind that there is a certain level of precision one gets with servos; past a
  // certain point, making the acceptable error smaller just makes you wait longer for the same
  // result. 

  // Start with the zero point.
  left_servo.zero_point = calibrate_servo_speed(left_servo, 0, 0.8, false);
  right_servo.zero_point = calibrate_servo_speed(right_servo, 0, 0.8, true);

  Serial << "Servos zeroed." << endl;

  // Next, the forward cruising speed
  left_servo.forward_point = calibrate_servo_speed(left_servo, cruise_speed, 1, false);
  right_servo.forward_point = calibrate_servo_speed(right_servo, cruise_speed, 1, true);

  Serial << "Servo forward speeds set." << endl;

  left_servo.servo.write(left_servo.zero_point);
  right_servo.servo.write(right_servo.zero_point);

  // Finally, the backward cruising speed.
  left_servo.backward_point = calibrate_servo_speed(left_servo, cruise_speed, 1, true);
  right_servo.backward_point = calibrate_servo_speed(right_servo, cruise_speed, 1, false);
  
  Serial << "Servo backward speeds set." << endl;

  left_servo.servo.write(left_servo.zero_point);
  right_servo.servo.write(right_servo.zero_point);

  attach_encoder_interrupts();

  Serial << "Done." << endl;
  Serial << "Calibration values:" << endl;
  Serial << "--- Left ---" << endl;
  Serial << "Z: " << left_servo.zero_point << " F: " << left_servo.forward_point 
         << " B: " << left_servo.backward_point << endl;
  Serial << "--- Right ---" << endl;
  Serial << "Z: " << right_servo.zero_point << " F: " << right_servo.forward_point 
         << " B: " << right_servo.backward_point << endl;
}

/* 
   Calibration Interrupt Service Routine.
*/
void calibration_isr_dec(){
  last_calibration_tick = millis();
  speed_calibration--;
}

void calibration_isr_inc(){
  last_calibration_tick = millis();
  speed_calibration++;
}

// ## Body functionality

void setup(){
  pinMode(13, OUTPUT);
  digitalWrite(13, LOW);

  Serial.begin(115200);

  // Set up servos. We have some default values for the calibration points, which were obtained
  // using the calibration routine above; if you find they're not working for you, run the
  // calibration again and enter their values here so you don't have to calibrate every time.
  // Calibration values:
  //    --- Left ---      |     --- Right ---
  // Z: 93 F: 84 B: 109   |  Z: 98 F: 107 B: 82

  left_servo.servo = Servo();
  left_servo.servo.attach(5);
  left_servo.encoder_interrupt = 0;
  left_servo.zero_point = 93;
  left_servo.forward_point = 84;
  left_servo.backward_point = 109;

  right_servo.servo = Servo();
  right_servo.servo.attach(10);
  right_servo.encoder_interrupt = 1;
  right_servo.zero_point = 98;
  right_servo.forward_point = 107;
  right_servo.backward_point = 82;

  attach_encoder_interrupts();

  blink(3);
  Serial << "Ready." << endl;
}

void loop(){
  // Read a char from serial buffer,
  if(Serial.available() > 0){
    char cmd = Serial.read();
    // see if they match any of our commands, and execute appropriate functions for each.
    switch(cmd){
    case 'f':
      move(true);
      break;
    case 'b':
      move(false);
      break;
    case 'r':
      rotate(true);
      break;
    case 'l':
      rotate(false);
      break;
    case 'c':
      calibrate_all();
      break;
    case 's':
      stop();
      Serial << "All stop!" << endl;
      break;
    default:
      Serial << "Unknown command " << cmd << "." << endl;
    }
  }
}

// ## Utility functions

void toggle(int pin){
  digitalWrite(pin, !digitalRead(pin));
}

void blink(int times){
  digitalWrite(13, LOW);
  for(int i = 0; i < times; i++){
    delay(250);
    toggle(13);
    delay(250);
    toggle(13);
  }
}
