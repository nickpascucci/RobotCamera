/*
  jpeg.cpp - A test to read data from the Linksprite JPEG camera.
 */

#define BUF_SIZE 64

#include <iostream>
#include <fstream>
#include <unistd.h>
#include <boost/system/error_code.hpp>
#include <boost/asio.hpp> 

void capture(std::ifstream&, std::ofstream&);
void send_array(char[], std::ifstream&, std::ofstream&);
void read_jpeg(std::ifstream&, std::ofstream&);

int main(int argc, char **argv){
  // open a file
  std::ifstream ser_input("/dev/ttyUSB0");
  std::ofstream ser_output("/dev/ttyUSB0");
  std::ofstream output_file("out.jpg");

  std::cout << "Capturing image." << std::endl;
  capture(ser_input, ser_output);
  
  sleep(.1);
  std::cout << "Done waiting for device." << std::endl;

  unsigned char expected[] = { 0x76, 0x00, 0x36, 0x00, 0x00 };
  unsigned char buf[5] = { 0xff };
  std::cout << "Reading response..." << std::endl;
  for(int i = 0; i < 5; i++){
    ser_input >> buf[i];
  }
 
  std::cout << "Validating." << std::endl;
  for(int i = 0; i < 5; i++){
    std::cout << std::hex << static_cast<int>(buf[i]);
    if(buf[i] != expected[i]){
      std::cout << " <- Mismatch!";
    }
    std::cout << std::endl;
  }

  // std::cout << "Reading JPEG from device." << std::endl;
  // read_jpeg(ser_input, output_file);

  // Close the file
  output_file.close();
}

void capture(std::ifstream& input_file, std::ofstream& output_file){
  char picture_command[] = { 0x56, 0x00, 0x36, 0x01, 0x00 };
  std::cout << "Sending command..." << std::endl;
  send_array(picture_command, input_file, output_file);
}

void send_array(char command[], std::ifstream& input_file, 
                std::ofstream& output_file){
  for(int i = 0; i < 5; i++){
    std::cout << "Sending byte " << i << "." << std::endl;
    output_file << command[i];  
  }  
}

// TODO this isn't correct. We need to read from specific memory addresses.
void read_jpeg(std::ifstream& input_file, std::ofstream& output_file){
  char jpeg_command[] = { 0x56, 0x00, 0x34, 0x01, 0x00 };
  send_array(jpeg_command, input_file, output_file);
  char next_char = 0;
  char last_char = 0;
  while(1){
    input_file >> next_char;
    output_file << next_char;

    // 0xFFD9 indicates the end of the JPEG file
    if(last_char == 0xFF && next_char == 0xD9){
        break;
    }
    last_char = next_char;
  }
}
