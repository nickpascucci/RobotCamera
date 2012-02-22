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
const float radius = 3.0;
const float circ = 2 * PI * radius;

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
  set_speed, // 004 - Matches index of kSEND_CMDS_END above.
  read_encoders, // 005
  read_speed, // 006
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
  Serial.print("1");
  Serial.print(field_separator);
  Serial.print(right_servo.speed, DEC);
  Serial.print(field_separator);
  Serial.print(left_servo.speed, DEC);
  Serial.println(command_separator);
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

  arduino_ready();  
}

void loop(){
  // Process incoming serial data, if any
  cmdMessenger.feedinSerialData();

  // TODO Handle servo speed setting here
  left_servo.servo.write(left_servo.speed);
  right_servo.servo.write(right_servo.speed);
}

void toggle(int pin){
  digitalWrite(pin, !digitalRead(pin));
}

/* void jerrys_base64_data(){ */
/*   // Afer base64_decode(), we just parse the buffer and unpack it into your */
/*   // target / desination data type eg bitmask, float, double, whatever. */
/*   char buf[350] = { 0x00 }; */
/*   boolean data_msg_printed = false; */

/*   // base64 decode */
/*   while ( cmdMessenger.available() ) */
/*   { */
/*     if(!data_msg_printed) */
/*     { */
/*       cmdMessenger.sendCmd(kACK, "what you send me, decoded base64..."); */
/*       data_msg_printed = true; */
/*     } */
/*     char buf[350] = { '\0' }; */
/*     cmdMessenger.copyString(buf, 350); */
/*     if(buf[0]) */
/*     { */
/*       char decode_buf[350] = { '\0' }; */
/*       base64_decode(decode_buf, buf, 350); */
/*       cmdMessenger.sendCmd(kACK, decode_buf); */
/*     } */
/*   } */

/*   // base64 encode */
/*   if(!data_msg_printed) */
/*   { */
/*     cmdMessenger.sendCmd(kACK, "\"the bears are allright\" encoded in base64..."); */
/*     char base64_msg[350] = { '\0' }; */
/*     base64_encode(base64_msg, "the bears are allright", 22); */
/*     cmdMessenger.sendCmd(kACK, base64_msg); */
/*   } */
/* } */
