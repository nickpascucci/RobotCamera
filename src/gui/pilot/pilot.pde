/*
  Processing-based GUI for controlling the rover.
*/

import controlP5.*;
import java.net.Socket;

// GUI objects
ControlP5 controlP5;
Textfield addressField;
Textarea statusArea;
color bgColor = color(0, 0, 0);
PFont libertine;
int start_x;
int start_y;

// Networking
Socket socket;
int DEFAULT_PORT = 9494;
InputStream input;
OutputStream output;

void setup(){
  // General window setup
  size(1200, 800);
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
  } else {
    controlP5.draw();
  }
}

void mouseDragged(){
  
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