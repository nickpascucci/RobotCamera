/*
  preprocess.cpp - Preprocessing utilities for JPEG images.

  Provides color to grayscale conversion, JPEG input and output, and feature
  detection. 
 */

#include <iostream>
#include <fstream>
#include <string>
#include <Magick++.h>

int main(int argc, char **argv){
  if(argc < 2){
    std::cout << "Usage: preprocess <file>" << std::endl;
    return 1;
  }
  
  using namespace Magick;
  Image image;
  image.read(argv[1]);
  double xres = image.yResolution();
  double yres = image.yResolution();
  std::cout << "Read in image, resolution " << xres << "x"
            << yres << std::endl;
  image.type(GrayscaleType);
  image.write("out.jpg");
  return 0;
}
