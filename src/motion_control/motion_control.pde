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

const int ticks_per_rev = 20;
const int cruise_speed = 18;

// ## Movement

void move(bool forward){
  if(forward){
    Serial << "Moving forward." << endl;
    // TODO move forward
  } else {
    Serial << "Moving backward." << endl;
    // TODO move back
  }
}

void rotate(bool clockwise){
  if(clockwise){
    Serial << "Rotating clockwise." << endl;
    // TODO
  } else {
    Serial << "Rotating counter-clockwise." << endl;
    // TODO
  }
}

void right_encoder_tick(){
  right_servo.ticks++;
  toggle(13);
}

void left_encoder_tick(){
  left_servo.ticks++;
  toggle(13);
}

// ## Calibration
// These two variables will be modified in interrupt contexts, so they need to be declared volatile.
volatile int speed_calibration = 0;
volatile long int last_calibration_tick;

// Find the point at which the servos move at a given speed.
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
  // It's up to you to reattach the right interrupt; I'm not going to do it for you.
  return speed_calibration;
}

// Calculate the current rotation speed in rpm from an encoder tick interval
inline float interval_to_speed(long interval){
  // Rotations per second = (ticks/second) / (ticks/rev)
  float tpm = 60000.0 / interval;
  return tpm / ticks_per_rev;
}

void calibrate_all(){
  Serial << "Calibrating..." << endl;
  // Bringing these parameters down will make the calibration take longer, but will detect smaller
  // errors. Keep in mind that there is a certain level of precision one gets with servos; past a
  // certain point, making the acceptable error smaller just makes you wait longer for the same
  // result. 
  left_servo.zero_point = calibrate_servo_speed(left_servo, 0, 0.8, false);
  right_servo.zero_point = calibrate_servo_speed(right_servo, 0, 0.8, true);

  left_servo.cruise_point = calibrate_servo_speed(left_servo, cruise_speed, 1, false);
  right_servo.cruise_point = calibrate_servo_speed(right_servo, cruise_speed, 1, true);
  
  left_servo.servo.write(left_servo.zero_point);
  right_servo.servo.write(right_servo.zero_point);
  Serial << "Done." << endl;
}

/* 
   Calibration Interrupt Service Routine.
*/
void calibration_isr(){
  last_calibration_tick = millis();
  speed_calibration--;
}

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

  // Set up encoders.
  attachInterrupt(0, right_encoder_tick, HIGH);
  attachInterrupt(1, left_encoder_tick, HIGH);

  // Set up servos.
  left_servo.servo = Servo();
  left_servo.servo.attach(5);
  left_servo.encoder_interrupt = 0;

  right_servo.servo = Servo();
  right_servo.servo.attach(10);
  right_servo.encoder_interrupt = 1;

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
