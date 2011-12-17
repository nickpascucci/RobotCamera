/*
  capture.cpp - A tool to read data from the Linksprite JPEG camera.
 */

#include <iostream>
#include <iomanip>
#include <fstream>
#include <unistd.h>
#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/system/error_code.hpp>

#define BUF_SIZE 64
#define MH_BYTE 8
#define ML_BYTE 9
#define KH_BYTE 12
#define KL_BYTE 13

bool capture(boost::asio::serial_port&);
uint16_t read_size(boost::asio::serial_port&);
void read_jpeg(boost::asio::serial_port&, std::ofstream&);

int main(int argc, char **argv){
  if(argc < 3 || argc > 4){
    std::cout << "Usage: capture <device> <file> [<baud rate>]" << std::endl;
    return 1;
  }
  int baud_rate = 38400; // default baud rate
  if(argc == 4){
    baud_rate = boost::lexical_cast<int>(argv[3]);
    std::cout << "Connecting at " << baud_rate << " baud." << std::endl;
  }

  std::string port(argv[1]);

  // Open serial port and JPEG file
  std::ofstream output_file(argv[2]); // Won't take a std::string, so pass char*
  boost::asio::io_service io;
  boost::asio::serial_port ser_port(io, port);
  
  ser_port.set_option(boost::asio::serial_port_base::baud_rate(baud_rate));

  if(not ser_port.is_open()){
    std::cout << "Failed to open serial port " << port << std::endl;
    return 3;
  }

  // Reset the camera.
  uint8_t reset[] = { 0x56, 0x00, 0x26, 0x00 };
  boost::asio::write(ser_port, boost::asio::buffer(reset, 5));

  // Read out initialization message.
  uint8_t discard[100] = { 0xff };
  boost::asio::read(ser_port, boost::asio::buffer(discard, 71));

  // Countdown!
  for(int i = 3; i > 0; i--){
    std::cout << "\rTaking image in " << i << "s." << std::flush;
    sleep(1);
  }
  std::cout << std::endl;

  // Instruct the camera to capture an image
  std::cout << "Capturing image... "; // Need space at end for failure message.

  if(capture(ser_port)){ // Success!
    std::cout << " Done." << std::endl;
    std::cout << "Reading image from camera..." << std::endl;

    // Read in the JPEG.
    read_jpeg(ser_port, output_file);
  }
  else {
    std::cout << "Capture failed. Check connection and try again." << std::endl;
  }

  // Close the output file and serial port.
  output_file.close();
  ser_port.close();
  return 0;
}

bool capture(boost::asio::serial_port& ser_port){
  // Send the take picture command to the device.
  uint8_t picture_command[] = { 0x56, 0x00, 0x36, 0x01, 0x00 };
  boost::asio::write(ser_port, boost::asio::buffer(picture_command, 5));

  // Validate the return value
  const uint8_t success[5] = { 0x76, 0x00, 0x36, 0x00, 0x00 };
  uint8_t return_val[5] = { 0x00 };
  boost::asio::read(ser_port, boost::asio::buffer(return_val, 5));

  for(int i = 0; i < 5; i++){
    if(success[i] != return_val[i]){
      return 0;
    }
  }
  return 1;
}

uint16_t read_size(boost::asio::serial_port& ser_port){
  // Write the command out to the serial port
  uint8_t size_command[] = { 0x56, 0x00, 0x34, 0x01, 0x00 };
  boost::asio::write(ser_port, boost::asio::buffer(size_command, 9));

  // Check the returned value against our reference. First 7 bytes should match.
  uint8_t return_ref[7] = { 0x76, 0x00, 0x34, 0x00, 0x04, 0x00, 0x00 };
  uint8_t return_val[9] = { 0x00 };
  boost::asio::read(ser_port, boost::asio::buffer(return_val, 9));

  for(int i = 0; i < 7; i++){
    if(return_val[i] != return_ref[i]){
      std::cout << "Mismatch in return value." << std::endl;
      return 0;
    }
  }

  // If all checks out, reconstruct the file size from bytes.
  uint16_t file_size = (return_val[7] << 8) | return_val[8];
  return file_size;
}

void read_jpeg(boost::asio::serial_port& ser_port, std::ofstream& output_file){
  uint8_t command[16] = { 0x56, 0x00, 0x32, 0x0C, 0x00, 0x0A, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0A };
  uint16_t m = 0; // Start address
  uint16_t k = 32; // Chunk size

  uint16_t file_size = read_size(ser_port);
  uint16_t bytes_read = 0;
  uint8_t last_byte = 0;

  bool done = false;
  while(!done) {
    uint8_t jpeg_data[32] = { 0x00 };

    // Build the command packet
    command[MH_BYTE] = (m >> 8) & 0xff;
    command[ML_BYTE] = (m >> 0) & 0xff;
    command[KH_BYTE] = (k >> 8) & 0xff;
    command[KL_BYTE] = (k >> 0) & 0xff;

    // Send it
    boost::asio::write(ser_port, boost::asio::buffer(command, 16));

    // Read off header of reply
    uint8_t header[5] = { 0x00 };
    boost::asio::read(ser_port, boost::asio::buffer(header, 5));
    if (header[0] == 0x76 && header[1] == 0x00 && header[2] == 0x32
        && header[3] == 0x00 && header[4] == 0x00){
      boost::asio::read(ser_port, boost::asio::buffer(jpeg_data, 32));
    } else {
      std::cout << "Header mismatch." << std::endl;
    }

    // Check for cross-packet end sequence
    if(last_byte == 0xFF && jpeg_data[0] == 0xD9){
      done = true;
    }

    // We're going to jump over the first byte, better write it out.
    output_file << jpeg_data[0];
    bytes_read++;

    // Write out the remaining bytes, and check to see if we've read the end.
    for(int i = 1; i < 32; i++){
      // Write data to output file...
      output_file << jpeg_data[i];
      bytes_read++;

      // Check for the end of the file.
      if(jpeg_data[i - 1] == 0xFF && jpeg_data[i] == 0xD9){
        done = true;
        break;
      }
    }

    // Stash our last byte to check for end sequence if it spans packets
    last_byte = jpeg_data[31];

    // Read footer, check for error conditions
    uint8_t footer[5] = { 0x00 };
    boost::asio::read(ser_port, boost::asio::buffer(footer, 5));
    if (!(footer[0] == 0x76 && footer[1] == 0x00 && footer[2] == 0x32
          && footer[3] == 0x00 && footer[4] == 0x00)){
      std::cout << "Mismatched footer!" << std::endl;
    }

    // Update address.
    m += 32;
    std::cout << "\rRead " << bytes_read << " of " << file_size 
              << " bytes." << std::flush;
  }
  std::cout << std::endl;
}
