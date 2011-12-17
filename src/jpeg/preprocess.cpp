/*
  preprocess.cpp - Preprocessing utilities for JPEG images.

  Provides color to grayscale conversion, JPEG input and output, and feature
  detection. 
 */

#include <iostream>
#include <fstream>
#include <string>
#include <boost/gil/extension/io/jpeg_io.hpp>

int main(int argc, char **argv){
  if(argc < 2){
    std::cout << "Usage: preprocess <file>" << std::endl;
    return 1;
  }
  boost::gil::point2<std::ptrdiff_t> size = boost::gil::jpeg_read_dimensions(argv[1]);
  std::cout << "Image dimensions: " << size[0] << "x" << size[1] << std::endl;

}
