/*
  Processing-based GUI for controlling the rover.
*/

import controlP5.*;
import java.awt.image.BufferedImage;
import java.awt.Image;
import java.io.ByteArrayInputStream;
import java.net.Socket;
import java.nio.ByteBuffer;
import javax.imageio.ImageIO;

// GUI objects
ControlP5 controlP5;
Textfield addressField;
Textarea statusArea;
color bgColor = color(0, 0, 0);
PFont libertine;
int start_x;
int start_y;

// Networking
int DEFAULT_PORT = 9494;
Socket socket;
InputStream input;
OutputStream output;

void setup(){
  // General window setup
  size(1280, 720);
  frame.setTitle("Pilot");
  background(bgColor);

  // Typography
  libertine = loadFont("libertine-100.vlw");

  // Initial GUI elements
  start_x= (width - 220)/2;
  start_y = (height/2)+25;

  controlP5 = new ControlP5(this);
  controlP5.setAutoDraw(false);
  drawConnectGui();
}

void draw(){
  if(socket != null){
    // Connected to robot.
    float start = millis();
    println("Requesting image from robot.");
    PImage pimage = requestImage();
    println("Done downloading, rendering image.");
    if(pimage != null){
      image(pimage, 0, 0, width, height);
      float elapsed_time = millis() - start;
      println("Elapsed time: " + elapsed_time + "ms");
    }
  } else {
    controlP5.draw();
  }
}

void mouseDragged(){
  
}

void keyTyped(){
  if(key == ESC){
    cleanUp();
    exit();
  }
}

void drawConnectGui(){
  // Nice, beautiful title text!
  textFont(libertine);
  text("Pilot", start_x, start_y - 25);

  // Some GUI elements... The spacing here is important.
  addressField = controlP5.addTextfield("address", start_x, start_y, 140, 20);
  controlP5.addButton("connect", 1, start_x + 155, start_y, 70, 20);

  // Text area for status messages. Should be the same width as above controls.
  statusArea = controlP5.addTextarea("status", "", start_x, start_y + 50, 
                                     215, 300);
}

void controlEvent(ControlEvent ev){
  Controller controller = ev.controller();
  if(controller.name().equals("connect")){
    connectToRobot();
  }
}

void connectToRobot(){
  print("Trying to connect to robot...");
  String host = addressField.getText();
  try {
    displayStatus("Contacting rover.");
    socket = new Socket(host, DEFAULT_PORT);
    displayStatus("Connection established!");
    input = socket.getInputStream();
    output = socket.getOutputStream();
  }
  catch(Exception e){
    displayStatus("Failed to connect to " + host + "!");
  }
}

void displayStatus(String status){
  println(status);
  String current_text = statusArea.text();
  current_text += "\n" + status;
  statusArea.setText(current_text);
}

PImage requestImage(){
  // TODO Expand this to work with the real protocol.
  // Read the image from the network into a buffered image
  try{
    output.write("IMAGE".getBytes());
    // Allocate more than we need into a flexible buffer.
    ByteBuffer buffer = ByteBuffer.allocate(2000*1100);
    while(input.available() > 0){
      buffer.put((byte) input.read());
    }

    InputStream imageBufferStream = new ByteArrayInputStream(buffer.array());
    BufferedImage image = ImageIO.read(imageBufferStream);

    // Since it's possible that we didn't get an image back, we'll check for
    // nulls.
    if(image != null){
      println("Read image from network stream.");
      // Create a Processing-compatible image buffer for the read image...
      PImage pimage = new PImage(image.getWidth(), image.getHeight(), 
                                 PConstants.ARGB);
      // Read the buffered image's pixel data into the Processing-compatible buffer
      image.getRGB(0, 0, pimage.width, pimage.height, 
                   pimage.pixels, 0, pimage.width);
      pimage.updatePixels();
      return pimage;
    } else {
      return null;
    }
  } catch (IOException ioe){
    return null;
  }
}

void cleanUp(){
  if(socket != null){
    try{
      output.write("QUIT".getBytes());
      input.close();
      output.close();
      socket.close();
    } catch (IOException ioe){
      // Do nothing, since it doesn't matter; we're closing shop.
    }
  }
}