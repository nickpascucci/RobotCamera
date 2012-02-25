/* -*- mode: c++; fill-column: 100; -*- */
/*
  Motion control Arduino sketch for the robot's servomotors. 

  Responds to commands over serial in order to move the robot. The following
  commands will be supported:

  Set speed: 4,<right_value>,<left_value>; 
  Move a servo at the given speed. Takes values from 0-255 in base 64 encoding.

  Read: 5;  
  Read the current position of the motor encoders.
*/

#include <Base64.h>
#include <CmdMessenger.h>
#include <Servo.h>
#include <Streaming.h>

// Communications
char command_separator = ';';
char field_separator = ',';
CmdMessenger cmdMessenger = CmdMessenger(Serial, field_separator, command_separator);

// Servo/Wheel info
const float radius = 3.0;           // Wheel radius
const float circ = 2 * PI * radius; // Wheel circumference
const float degrees_per_tick = 20;  // Encoder resolution

// Target move distance. When this is nonzero loop() will move forward this number of ticks.
int target_dist = 0;

struct EncodedServo {
  Servo servo;
  int encoder_interrupt;
  int zero_point;
  int speed;
  int ticks;
  long int last_tick;
};

EncodedServo left_servo;
EncodedServo right_servo;

// Arduino -> PC messages
enum {
  kCOMM_ERROR = 000,
  kACK = 001,
  kARDUINO_READY = 002,
  kERR = 003,

  kSEND_CMDS_END, // 004
};

// PC -> Arduino commands
messengerCallbackFunction messengerCallbacks[] =
  {
    set_speed,        // 004 - Matches index of kSEND_CMDS_END above.
    read_encoders,    // 005
    read_speed,       // 006
    move_dist,        // 007
    zero_servos,      // 008
  };

void set_speed(){
  // We'll loop through the arguments
  int servo_num = 0;
  while(cmdMessenger.available()){
    char buf[10] = { 0x00 };
    cmdMessenger.copyString(buf, 10);
    cmdMessenger.sendCmd(kACK, buf);
    char decoded_buf[10] = { 0x00 };
    base64_decode(decoded_buf, buf, 10);

    // checking to see which side we should set.
    if(servo_num == 0){ 
      right_servo.speed = (int) decoded_buf[0];
    } 
    else if(servo_num == 1){
      left_servo.speed = (int) decoded_buf[0];
    }
    servo_num++;
  }
  cmdMessenger.sendCmd(kACK, "Speed set");
}

void read_encoders(){
  // Get encoder data and send it to the computer
  Serial.print("1");
  Serial.print(field_separator);
  Serial.print(right_servo.ticks, DEC);
  Serial.print(field_separator);
  Serial.print(left_servo.ticks, DEC);
  Serial.println(command_separator);
}

void read_speed(){
  // Print current speed information to the serial port
  Serial.print("1");
  Serial.print(field_separator);
  Serial.print(right_servo.speed, DEC);
  Serial.print(field_separator);
  Serial.print(left_servo.speed, DEC);
  Serial.println(command_separator);
}

void move_dist(){
  // Parse distance from packet, and set it as global target
  if(cmdMessenger.available()){
    char buf[10] = { 0x00 };
    cmdMessenger.copyString(buf, 10);
    char decoded_buf[10] = { 0x00 };

    // Targets will be base 64 encoded bytes, so we'll need to decode them.
    base64_decode(decoded_buf, buf, 10);
    target_dist = decoded_buf[0];

    // Send a confirmation back to the desktop.
    Serial.print("1,");
    Serial.print("Target distance set at ");
    Serial.print(target_dist, DEC);
    Serial.print("cm;");

    // Re-encode the distance in terms of ticks; these are a lot easier to track.
    target_dist = dist_to_ticks(target_dist);
  }
  cmdMessenger.sendCmd(kACK, "Moving forward.");
}

int dist_to_ticks(int dist){
  // The number of ticks for a given distance is given by the number of revolutions divided by the
  // number of ticks per revolution.
  int ticks = (dist/circ) / (360/degrees_per_tick);
  return ticks;
}

void arduino_ready(){
  cmdMessenger.sendCmd(kACK,"Ready");
}

void unknown_cmd(){
  cmdMessenger.sendCmd(kERR,"Unknown command");
}

void attach_callbacks(messengerCallbackFunction* callbacks){
  int i = 0;
  int offset = kSEND_CMDS_END;
  while(callbacks[i])
    {
      cmdMessenger.attach(offset+i, callbacks[i]);
      i++;
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

int speed_calibration = 0;
long int last_calibration_tick;
void zero_servos(){
  // Calibration routine:
  // Set the servo to full speed
  speed_calibration = 180;
  noInterrupts();
  left_servo.servo.write(speed_calibration);
  // Attach a calibration interrupt which decreases speed every time the encoder ticks
  detachInterrupt(left_servo.encoder_interrupt);
  attachInterrupt(left_servo.encoder_interrupt, calibration_isr, RISING);
  interrupts();
  last_calibration_tick = millis();
  cmdMessenger.sendCmd(kACK, "Starting left servo calibration");
  while(millis() - last_calibration_tick < 5000){
    left_servo.servo.write(speed_calibration);
  };

  // Save the speed.
  left_servo.zero_point = speed_calibration - 1;
  cmdMessenger.sendCmd(kACK, "Left servo calibrated");

  // Repeat for the other servo.
  speed_calibration = 180;
  noInterrupts();
  right_servo.servo.write(speed_calibration);

  detachInterrupt(right_servo.encoder_interrupt);
  attachInterrupt(right_servo.encoder_interrupt, calibration_isr, RISING);
  interrupts();
  last_calibration_tick = millis();
  cmdMessenger.sendCmd(kACK, "Starting right servo calibration");
  while(millis() - last_calibration_tick < 5000){
    right_servo.servo.write(speed_calibration);
  };

  right_servo.zero_point = speed_calibration - 1;
  cmdMessenger.sendCmd(kACK, "Right servo calibrated");

  // Clean up by reattaching interrupts:
  detachInterrupt(left_servo.encoder_interrupt);
  detachInterrupt(right_servo.encoder_interrupt);
  attachInterrupt(left_servo.encoder_interrupt, left_encoder_tick, HIGH);
  attachInterrupt(right_servo.encoder_interrupt, right_encoder_tick, HIGH);
}

/* 
   Calibration Interrupt Service Routine, used to find the zero point on the servos.
*/
void calibration_isr(){
  last_calibration_tick = millis();
  speed_calibration--;
}

void setup(){
  pinMode(13, OUTPUT);
  digitalWrite(13, LOW);

  Serial.begin(115200);
  // Make output more readable.
  cmdMessenger.print_LF_CR(); 
  
  // Attach default/generic callback methods.
  cmdMessenger.attach(kARDUINO_READY, arduino_ready);
  cmdMessenger.attach(unknown_cmd);

  // Attach application callback methods.
  attach_callbacks(messengerCallbacks);

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

  zero_servos();

  arduino_ready();  
}

void loop(){
  // Process incoming serial data, if any
  cmdMessenger.feedinSerialData();

  // TODO Handle servo speed setting here
  if(target_dist > left_servo.ticks){
    left_servo.servo.write(left_servo.speed);
  }
  else {
    left_servo.servo.write(left_servo.zero_point);
  }
  if(target_dist > right_servo.ticks){
    right_servo.servo.write(right_servo.speed);
  }
  else {
    right_servo.servo.write(right_servo.zero_point);
  }

}

void toggle(int pin){
  digitalWrite(pin, !digitalRead(pin));
}
