/*
 camtool.cpp - Integrated camera tool that lets you take pictures with different
 resolutions, speeds, and compression ratios.

 Usage: camtool [-p<device>] [-f<file>] [-r<resolution>] [-b<rate>] [-t<rate>] 
                [-c<ratio>] [-v]
 
 Options:
  -p<device> Device file. Defaults to /dev/ttyUSB0.
  -f<file>   Output filename. Defaults to out.jpg.
  -r<res>    Set the device resolution. Available resolutions:
             160x120, 320x240, 640x480
  -b<rate>   Set the current device baud rate. Available rates:
             9600, 19200, 38400, 57600, 115200. Default: 38400
  -t<rate>   Set the device data transfer baud rate. Available rates:
             9600, 19200, 38400, 57600, 115200. Default: 115200
  -c<ratio>  Set the JPEG compression ratio. Available ratios:
             00 to FF
  -v         Turn on verbose mode.
 */

#include <fstream>
#include <iostream>
#include <inttypes.h>
#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/system/error_code.hpp>

#define BUF_SIZE 64
#define MH_BYTE 8
#define ML_BYTE 9
#define KH_BYTE 12
#define KL_BYTE 13

void get_options(struct Options&, int, char**);
bool capture(boost::asio::serial_port&);
uint16_t read_size(boost::asio::serial_port&);
void read_jpeg(boost::asio::serial_port&, std::ofstream&);
bool set_baud(boost::asio::serial_port&, int);
bool set_resolution(boost::asio::serial_port&, int, int);
bool set_compression(boost::asio::serial_port&, int);
bool ends_with(std::string&, std::string&);

struct Options{
  std::string out_file;
  std::string port;
  int x_res;
  int y_res;
  int baud;
  int transfer;
  int compress;
  bool verbose;
};

// Baud rate packets
uint8_t set_9600[] = {0x56, 0x00, 0x24, 0x03, 0x01, 0xAE, 0xC8};
uint8_t set_19200[] = {0x56, 0x00, 0x24, 0x03, 0x01, 0x56, 0xE4};
uint8_t set_38400[] = {0x56, 0x00, 0x24, 0x03, 0x01, 0x2A, 0xF2};
uint8_t set_57600[] = {0x56, 0x00, 0x24, 0x03, 0x01, 0x1C, 0x4C};
uint8_t set_115200[] = {0x56, 0x00, 0x24, 0x03, 0x01, 0x0D, 0xA6};
uint8_t baud_return_success[] = {0x76, 0x00, 0x24, 0x00, 0x00};

// Resolution packets
uint8_t set_160120[] = {0x56, 0x00, 0x31, 0x05, 0x04, 0x01, 0x00, 0x19, 0x22};
uint8_t set_320240[] = {0x56, 0x00, 0x31, 0x05, 0x04, 0x01, 0x00, 0x19, 0x11};
uint8_t set_640480[] = {0x56, 0x00, 0x31, 0x05, 0x04, 0x01, 0x00, 0x19, 0x00};
uint8_t resolution_return_success[] = {0x76, 0x00, 0x31, 0x00, 0x00};

uint8_t reset[] = { 0x56, 0x00, 0x26, 0x00 };

int main(int argc, char **argv){
  struct Options options;
  get_options(options, argc, argv);
  
  if(options.verbose){
    std::cout << "Options parsed, beginning run." << std::endl;
  }

  // Open serial port and JPEG file
  std::ofstream output_file(options.out_file.c_str());
  if(options.verbose){
    std::cout << "Opened output file " << options.out_file << "." << std::endl;
  }  
  boost::asio::io_service io;
  boost::asio::serial_port ser_port(io, options.port);
  
  // Set the initial baud rate
  ser_port.set_option(boost::asio::serial_port_base::baud_rate(options.baud));

  if(not ser_port.is_open()){
    std::cout << "Failed to open serial port " << options.port << std::endl;
    return 3;
  } else if(options.verbose){
    std::cout << "Opened serial port " << options.port << "." << std::endl;
  }

  // Reset the camera.
  boost::asio::write(ser_port, boost::asio::buffer(reset, 4));
  if(options.verbose){
    std::cout << "Camera reset sent." << std::endl;
  }

  // Read out initialization message.
  uint8_t discard[70];
  bool init_done = false;
  while(!init_done){
    int read = boost::asio::read(ser_port, boost::asio::buffer(discard, 5));
    if(discard[read - 1] == '5'){
      init_done = true;
    }
    if(options.verbose){
      std::cout << std::string(reinterpret_cast<char *>(discard)); 
    }
  }
  if(options.verbose){
    std::cout << std::endl;
    std::cout << "Flushed buffer." << std::endl;
    std::cout << "Attempting to set baud rate on device." << std::endl;
  }

  // Set baud rate
  if(!set_baud(ser_port, options.transfer)){
    ser_port.close();
    std::cout << "Failed to set baud rate. Aborting!" << std::endl;
    return 1;
  }
  ser_port.set_option(boost::asio::serial_port_base::baud_rate(options.transfer));
  if(options.verbose){
    std::cout << "Set and matched baud rate on device." << std::endl;
  }

  // Set resolution
  // Set compression ratio

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
    if(options.verbose){
      std::cout << "Capture complete." << std::endl;
    }
  }
  else {
    std::cout << "Capture failed. Check connection and try again." << std::endl;
  } 
  
  // Close the output file and serial port.
  output_file.close();
  ser_port.close();
  return 0;
}

void get_options(struct Options& options, int argc, char **argv){
  // Defaults
  options.out_file = "out.jpg";
  options.port = "/dev/ttyUSB0";
  options.x_res = 160;
  options.y_res = 120;
  options.transfer = 115200;
  options.baud = 38400;
  options.compress = 0x36;
  options.verbose = false;
  std::string requested_resolution;

  while((argc > 1) && (argv[1][0] == '-')){
    switch(argv[1][1]){
    case 'p':
      options.port = std::string(argv[1] + 2);
      std::cout << "Set port to " << options.port << std::endl;
      break;
    case 'f':
      options.out_file = argv[1] + 2;
      std::cout << "Set output file to " << options.out_file << std::endl;
      break;
    case 'r':
      requested_resolution = std::string(argv[1] + 2);
      if(requested_resolution == "160x120"){
        options.x_res = 160;
        options.y_res = 120;
      } else if(requested_resolution == "320x240"){
        options.x_res = 320;
        options.y_res = 240;
      } else if(requested_resolution == "640x480"){
        options.x_res = 640;
        options.y_res = 480;
      } else {
        std::cout << "Invalid resolution " << requested_resolution
                  << ". Defaulting to 160x120." << std::endl;
      }
      std::cout << "Set resolution to " << options.x_res << "x" << options.y_res
                << std::endl;
      break;
    case 'b':
      options.baud = boost::lexical_cast<int>(argv[1] + 2);
      std::cout << "Set baud to " << options.baud << std::endl;
      break;
    case 't':
      options.transfer = boost::lexical_cast<int>(argv[1]);
      std::cout << "Set transfer to " << options.transfer << std::endl;
      break;
    case 'c':
      //TODO Requires some more complex parsing.
      break;
    case 'v':
      options.verbose = true;
      break;
    }
    // Move the pointer forward one element and decrement our argument count.
    ++argv;
    --argc;
  }
  // TODO
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

bool set_baud(boost::asio::serial_port& ser_port, int baud_rate){
  uint8_t *baud_command;
  switch(baud_rate){
  case 9600:
    baud_command = set_9600;
    break;
  case 19200:
    baud_command = set_19200;
    break;
  case 38400:
    baud_command = set_38400;
    break;
  case 57600:
    baud_command = set_57600;
    break;
  case 115200:
    baud_command = set_115200;
    break;
  default:
    std::cout << "Invalid baud rate, aborting." << std::endl;
    return 1;
  }
  boost::asio::write(ser_port, boost::asio::buffer(baud_command, 7));
  uint8_t baud_verify[5] = { 0x00 };
  boost::asio::read(ser_port, boost::asio::buffer(baud_verify, 5));
  for(int i = 0; i < 5; i++){
    if(baud_verify[i] != baud_return_success[i]){
      return false;
    }
  }
  return true;
}

bool set_resolution(boost::asio::serial_port& ser_port, int x_res, int y_res){
  return false;
}

bool set_compression(boost::asio::serial_port& ser_port, int ratio){
  return false;
}

bool ends_with (std::string const &full_string, std::string const &ending)
{
    if (full_string.length() >= ending.length()) {
        return (0 == full_string.compare (full_string.length() - ending.length(), ending.length(), ending));
    } else {
        return false;
    }
}
