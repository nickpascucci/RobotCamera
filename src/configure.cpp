/*
  configure.cpp - Configure camera parameters.
  
  Lets you set the camera's resolution, compression ratio, and serial rate.
 */

#include <iostream>
#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/system/error_code.hpp>

void change_resolution(std::string, int);
int change_baud_rate(std::string, int);
int get_baud_selection(void);
bool send_and_verify(std::string, int, uint8_t*, std::size_t, 
                     uint8_t*, std::size_t);
void send_and_clear(std::string port, int baud_rate, uint8_t *command,
                    std::size_t clen, std::size_t discard_bytes);

int main(int argc, char** argv){
  if(argc < 3){
    // Since we might have set the device to a non-standard baud rate, we'll
    // need to take it as a parameter to our program.
    std::cout << "Usage: configure <device> <baud rate>" << std::endl;
    return 1;
  }

  std::string port(argv[1]);
  int baud_rate = boost::lexical_cast<int>(argv[2]);
  
  std::cout << "LinkSprite Camera Configuration Tool v1.0" << std::endl;
  std::cout << "Working on device " << port << " at baud " << baud_rate << "." 
            << std::endl;

  // Reset the device to make sure it works
  std::cout << "Attempting to reset device... " << std::flush;
  uint8_t reset[] = {0x56, 0x00, 0x26, 0x00};
  uint8_t reset_reply[] = {0x76, 0x00, 0x26, 0x00};

  if(!send_and_verify(port, baud_rate, reset, 4, reset_reply, 4)){
    std::cout << "Reset was unsuccessful, aborting!" << std::endl;
    return 1;
  }
  std::cout << "Success!" << std::endl;

  std::cout << "What do you want to do?" << std::endl;

  // Ok, now for a menu.
  while(true){
    std::cout << "Change [r]esolution" << std::endl;
    std::cout << "Change [b]aud rate" << std::endl;
    std::cout << "[Q]uit" << std::endl;

    char operation;
    std::cin >> operation;

    if(operation == 'r' || operation == 'R'){
      change_resolution(port, baud_rate);
    }
    else if(operation == 'b' || operation == 'B'){
      // When we change baud rates, we need to switch to the new rate for 
      // subsequent communication.
      baud_rate = change_baud_rate(port, baud_rate);
      if(baud_rate < 0){
        std::cout << "Could not set baud rate successfully, aborting." 
                  << std::endl;
        return 1;
      }
    }
    else if(operation == 'q' || operation == 'Q'){
      std::cout << "Reminder: current baud rate is " << baud_rate 
                << "." << std::endl;
      return 0;
    }
  }
}

void change_resolution(std::string port, int current_baud){
  int selection;
  char confirmation;
  uint8_t set_160120[] = {0x56, 0x00, 0x31, 0x05, 0x04, 0x01, 0x00, 0x19, 0x22};
  uint8_t set_320240[] = {0x56, 0x00, 0x31, 0x05, 0x04, 0x01, 0x00, 0x19, 0x11};
  uint8_t set_640480[] = {0x56, 0x00, 0x31, 0x05, 0x04, 0x01, 0x00, 0x19, 0x00};
  uint8_t verification[] = {0x76, 0x00, 0x31, 0x00, 0x00};

  std::cout << "Changing camera resolution." << std::endl;
  std::cout << "Available resolutions:" << std::endl;
  std::cout << "1) 160x120" << std::endl;
  std::cout << "2) 320x240" << std::endl;
  std::cout << "3) 640x480" << std::endl;
  std::cout << "4) Abort" << std::endl;
  std::cin >> selection;

  uint8_t *command = set_160120;
  switch(selection){
  case 1:
    std::cout << "Selected 160x120." << std::endl;
    break;
  case 2:
    command = set_320240;
    std::cout << "Selected 320x240." << std::endl;
    break;
  case 3:
    command = set_640480;
    std::cout << "Selected 640x480." << std::endl;
    break;
  default:
    std::cout << "Aborting." << std::endl;
    return;
  }

  std::cout << "Send to camera? [y/n] ";
  std::cin >> confirmation;

  if(confirmation == 'y' || confirmation == 'Y'){
    std::cout << "Committing." << std::endl;
    if(send_and_verify(port, current_baud, command, 9, verification, 5)){
      std::cout << "Done! Resolution set and verified." << std::endl;
      // Reset the device.
    }
    else {
      std::cout << "Setting resolution failed." << std::endl;
    }
  }
  else {
    std::cout << "Aborting." << std::endl;
    return;
  } 
}

int change_baud_rate(std::string port, int current_baud){
  int baud_selection;
  int baud_rate;
  // These are the available baud rates, and a template packet to set them.
  uint8_t baud_set_command[] = {0x56, 0x00, 0x24, 0x03, 0x01, 0x00, 0x00};
  uint8_t baud_return_success[] = {0x76, 0x00, 0x24, 0x00, 0x00};
  // These two-byte combinations will replace the two null bytes at the end.
  uint8_t set_9600[] = {0xAE, 0xC8};
  uint8_t set_19200[] = {0x56, 0xE4};
  uint8_t set_38400[] = {0x2A, 0xF2};
  uint8_t set_57600[] = {0x1C, 0x4C};
  uint8_t set_115200[] = {0x0D, 0xA6};
  
  baud_selection = get_baud_selection();

  // We'll select the appropriate two-byte combination using a switch.
  uint8_t *baud_component = set_9600;
  baud_rate = 9600;
  switch(baud_selection){
    // Default case is 9600.
  case 2:
    baud_component = set_19200;
    baud_rate = 19200;
    break;
  case 3:
    baud_component = set_38400;
    baud_rate = 38400;
    break;
  case 4:
    baud_component = set_57600;
    baud_rate = 57600;
    break;
  case 5:
    baud_component = set_115200;
    baud_rate = 115200;
    break;
  default:
    std::cout << "Aborting." << std::endl;
    return -1;
  }

  // The last two bytes of the packet tell the device what baud to use
  baud_set_command[5] = baud_component[0];
  baud_set_command[6] = baud_component[1];

  std::cout << "DEBUG: Array contents" << std::endl;
  for(int i=0; i<7; i++){
    int br = baud_set_command[i];
    std::cout << std::hex << br << " ";
  }
  std::cout << std::flush << std::dec << std::endl;

  if(send_and_verify(port, current_baud, baud_set_command, 7, 
                     baud_return_success, 5)){
    std::cout << "Baud rate set successfully. Now communicating at " 
              << baud_rate << " baud." << std::endl;
    return baud_rate;
  }
  else {
    return -1;
  }
}

int get_baud_selection(){
  int baud_rate = 0;
  while(!baud_rate){
    std::cout << "Available baud rates:" << std::endl;
    std::cout << "1) 9600" << std::endl;
    std::cout << "2) 19200" << std::endl;
    std::cout << "3) 38400" << std::endl;
    std::cout << "4) 57600" << std::endl;
    std::cout << "5) 115200" << std::endl;
    std::cout << "6) Abort" << std::endl << std::endl;
    std::cout << "New baud rate: " << std::endl;
    std::cin >> baud_rate;
    if(baud_rate < 1 || baud_rate > 6){
      std::cout << "That's not an option. What, do you think you can just wish "
                << "for new baud rates? Pick one from the list, man." 
                << std::endl;
      baud_rate = 0;
    }
  }
  return baud_rate;
}

bool send_and_verify(std::string port, int baud_rate, uint8_t *command, 
                     std::size_t clen, uint8_t *verification, std::size_t vlen){
  // Set up a serial connection to the device with our current baud rate
  boost::asio::io_service io;
  boost::asio::serial_port ser_port(io, port);
  ser_port.set_option(boost::asio::serial_port_base::baud_rate(baud_rate));
  
  if(not ser_port.is_open()){
    std::cout << "Failed to open serial port " << port << std::endl;
    return false;
  }
  // Send the packet
  boost::asio::write(ser_port, boost::asio::buffer(command, clen));

  // Check the reply from the device
  uint8_t *reply; // Reply array allocated dynamically
  reply = new uint8_t[vlen];
  memset(reply, 0, vlen); // Set the array to 0
  bool pass_verification = true;
  boost::asio::read(ser_port, boost::asio::buffer(reply, vlen));

  // Verify the reply is correct...
  for(std::size_t i = 0; i < vlen; i++){
    if(reply[i] != verification[i]){
      pass_verification = false;
    }
  }

  ser_port.close();
  delete [] reply; // Free up that memory.
  return pass_verification;
}

void send_and_clear(std::string port, int baud_rate, uint8_t *command,
                    std::size_t clen, std::size_t discard_bytes){
  // Set up a serial connection to the device with our current baud rate
  boost::asio::io_service io;
  boost::asio::serial_port ser_port(io, port);
  ser_port.set_option(boost::asio::serial_port_base::baud_rate(baud_rate));

  if(not ser_port.is_open()){
    std::cout << "Failed to open serial port " << port << std::endl;
    return;
  }

  // Send the packet
  boost::asio::write(ser_port, boost::asio::buffer(command, clen));
  
  // Discard the reply from the device
  uint8_t *reply; // Reply array allocated dynamically
  reply = new uint8_t[discard_bytes];
  boost::asio::read(ser_port, boost::asio::buffer(reply, discard_bytes));
  ser_port.close();
  delete [] reply; // Free up that memory.
}
