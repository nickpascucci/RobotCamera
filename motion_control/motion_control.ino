/* -*- mode: c; fill-column: 100; -*- */
/*
   Motion control Arduino sketch for the robot's servomotors. 

   Responds to commands over serial in order to move the robot. The following
   commands will be supported:

   set_speed;[R/L]<value> Move a servo at the given speed. Negative values means move backwards.
   read;                  Read the current position of the motor encoders.

   Notes:

   - You'll need to modify Streaming.h to get it to compile with the new Arduino
     environment. Since WProgram.h is no more, change the #include line to use
     Arduino.h instead.
 */

#include <Base64.h>
#include <CmdMessenger.h>
#include <Servo.h>
#include <Streaming.h>

char command_separator = ";";
char field_separator = ",";
CmdMessenger cmdMessenger = CmdMessenger(Serial, field_separator, command_separator);

// Encoder data
int left_clicks = 0;
int right_clicks = 0;

// Servo info
const int right_servo_pin = 5;
const int left_servo_pin = 10;

// Arduino -> PC messages
enum
{
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
};

void set_speed(){
  // Read the speed value
}

void read_encoders(){
  // Get encoder data, package it as a pair of strings
  String right_encoder_data = String(right_ticks, DEC);
  String left_encoder_data = String(left_ticks, DEC);

  // Build a new string with that data
  String encoder_data_string = String("R" + right_encoder_data + "L" + left_encoder_data);

  // Convert the new string to a char array
  char encoder_data[] = new char[encoder_data_string.length() + 1];
  encoder_data_string.toCharArray(encoder_data, encoder_data_string.length() + 1);

  // Send it
  cmdMessenger.sendCmd(encoder_data);

  // Free up memory
  delete encoder_data;
}

void arduino_ready(){
  cmdMessenger.sendCmd(kACK,"Ready");
}

void unknown_cmd(){
  cmdMessenger.sendCmd(kERR,"Unknown command");
}

void attach_callbacks(messengerCallbackFunction* callbacks)
{
  int i = 0;
  int offset = kSEND_CMDS_END;
  while(callbacks[i])
  {
    cmdMessenger.attach(offset+i, callbacks[i]);
    i++;
  }
}

void jerrys_base64_data()
{
  // Afer base64_decode(), we just parse the buffer and unpack it into your
  // target / desination data type eg bitmask, float, double, whatever.
  char buf[350] = { 0x00 };
  boolean data_msg_printed = false;

  // base64 decode
  while ( cmdMessenger.available() )
  {
    if(!data_msg_printed)
    {
      cmdMessenger.sendCmd(kACK, "what you send me, decoded base64...");
      data_msg_printed = true;
    }
    char buf[350] = { '\0' };
    cmdMessenger.copyString(buf, 350);
    if(buf[0])
    {
      char decode_buf[350] = { '\0' };
      base64_decode(decode_buf, buf, 350);
      cmdMessenger.sendCmd(kACK, decode_buf);
    }
  }

  // base64 encode
  if(!data_msg_printed)
  {
    cmdMessenger.sendCmd(kACK, "\"the bears are allright\" encoded in base64...");
    char base64_msg[350] = { '\0' };
    base64_encode(base64_msg, "the bears are allright", 22);
    cmdMessenger.sendCmd(kACK, base64_msg);
  }
}

void setup(){
  Serial.begin(115200);
  cmdMessenger.print_LF_CR(); // Make output more readable
  
  // Attach default / generic callback methods
  cmdMessenger.attach(kARDUINO_READY, arduino_ready);
  cmdMessenger.attach(unknown_cmd);

  // Attach application callback methods
  attach_callbacks(messengerCallbacks);

  arduino_ready();  
}

void loop(){
  // Process incoming serial data, if any
  cmdMessenger.feedinSerialData();
}
