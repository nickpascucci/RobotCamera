/*
  Processing-based GUI for controlling the rover.
*/

import controlP5.*;
import bluetoothDesktop.*;
import java.awt.image.BufferedImage;
import java.awt.Image;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;
import java.io.ByteArrayInputStream;
import java.net.Socket;
import java.nio.ByteBuffer;
import javax.imageio.ImageIO;

// GUI objects
ControlP5 controlP5;
Textfield addressField;
Textarea statusArea;
TextButton btButton;
TextButton netButton;
color bgColor = color(0, 0, 0);
color selectedTextColor = color(0, 143, 191); //color(0, 115, 153);
color unselectedTextColor = color(0xFB, 0xFB, 0xFB);
PFont libertine;
PFont dejavusans;
int start_x;
int start_y;

// Overlay button information
OverlayButton edgeDetectButton;
OverlayButton doorDetectButton;
OverlayButton rawViewButton;
boolean mouseDown = false;
int mouseDownX = 0;
int mouseDownY = 0;

// Speeding up rendering by scaling images nicely? Yes please.
int imgScaleX = 0;
int imgScaleY = 0;
int imgOffsetX = 0;
int imgOffsetY = 0;

// Networking
// TODO Pull all of the networking crap into its own set of classes so we can
// abstract network/bluetooth
int DEFAULT_VIDEO_PORT = 9494;
int DEFAULT_CONTROL_PORT = 9495;
Socket videoSocket;
InputStream videoInput;
OutputStream videoOutput;
Socket controlSocket;
InputStream controlInput;
OutputStream controlOutput;
boolean image_request_pending = false;


void setup(){
  // General window setup.
  if(screenWidth < 1920){ // Detect large screens, and avoid overfilling
    size(screenWidth, screenHeight, P2D);
  } else {
    size(1280, 960, P2D);
  }
  frame.setTitle("Pilot");
  background(bgColor);

  // Typography
  libertine = loadFont("libertine-100.vlw");
  dejavusans = loadFont("dejavusans-24.vlw");

  // Set up listeners
  addMouseMotionListener(new MouseMotionListener(){
      public void mouseDragged(MouseEvent e){
        onMouseDragged(e.getButton(), e.getX(), e.getY());
      } 

      public void mouseMoved(MouseEvent e){ 
        // Do nothing 
      }
    });

  addMouseListener(new MouseListener(){
      public void mouseClicked(MouseEvent e){
        // Do nothing
      }

      public void mouseEntered(MouseEvent e){
        // Do nothing
      }
      public void mouseExited(MouseEvent e){
        // Do nothing
      }
      public void mousePressed(MouseEvent e){
        onMousePressed(e.getButton(), e.getX(), e.getY());
      }
      public void mouseReleased(MouseEvent e){
        onMouseReleased(e.getButton(), e.getX(), e.getY());
      }
    });

  // Initial GUI elements
  start_x= (width - 220)/2;
  start_y = (height/2)+25;

  controlP5 = new ControlP5(this);
  controlP5.setAutoDraw(false);
  drawConnectGui();

  edgeDetectButton = new OverlayButton(-60, 0, loadImage("left_normal.png"), 
                                       loadImage("left_selected.png"));
  rawViewButton = new OverlayButton(0, 60, loadImage("top_normal.png"), 
                                    loadImage("top_selected.png"));
  doorDetectButton = new OverlayButton(60, 0, loadImage("right_normal.png"), 
                                       loadImage("right_selected.png"));
}

void draw(){
  if(videoSocket != null){
    // Connected to robot.
    long start_time = System.currentTimeMillis();
    PImage pimage = requestImage();
    long got_image_in = System.currentTimeMillis() - start_time;
    // println("Image retrieved in " + got_image_in + "ms");
    if(pimage != null){
      // println("Resolution of image: " + pimage.width + "x" + pimage.height);
      if(imgScaleX == 0){
        // We'll try to speed up the render with precomputed scaling/translation
        computeImageScaling(pimage.width, pimage.height);
      }
      noSmooth(); // Turn off smoothing for faster render.
      imageMode(CORNER);
      image(pimage, imgOffsetX, imgOffsetY, imgScaleX, imgScaleY);
      long rendered_in = System.currentTimeMillis() - start_time - got_image_in;
      // println("Rendered in " + rendered_in + "ms");
    }
    // We need to check for the mouse being pressed in order to draw over
    // successive frames.
    if(mouseDown){
      drawOverlayUi(mouseDownX, mouseDownY);
    }
  } else {
    background(0);
    drawTitle();
    btButton.draw();
    netButton.draw();
    if(netButton.isSelected()){
      controlP5.draw();
    }
  }
}

/*
  Generate an optimal scaling factor by successive doubling.
*/
void computeImageScaling(int xSize, int ySize){
  imgScaleX = xSize;
  imgScaleY = ySize;

  // While we're still in bounds, increase the image size.
  // This should only happen once, or maybe twice if the image is small.
  while(imgScaleX + xSize <= width && imgScaleY + ySize <= height){
    imgScaleX += xSize;
    imgScaleY += ySize;
  }
  // Calculate the new offsets so we center the image properly.
  imgOffsetX = (width - imgScaleX) / 2;
  imgOffsetY = (height - imgScaleY) / 2;
}

void mouseClicked(){
  if(videoSocket == null) {
    if(btButton.contains(mouseX, mouseY)){
      btButton.setSelected(true);
      netButton.setSelected(false);
    } else if (netButton.contains(mouseX, mouseY)){
      netButton.setSelected(true);
      btButton.setSelected(false);
    }
  }
}

/*
  Respond to mouse input events.
*/
void onMouseDragged(int button, int x, int y){
  if(videoSocket != null && mouseDown){
    // Connected to robot, so let's do some UI magic!
    // Check the location of the mouse and see if it's in any of our buttons.
    // If it is, highlight the button.
    if(edgeDetectButton.contains(x, y)){
      edgeDetectButton.setSelected(true);
    } else {
      edgeDetectButton.setSelected(false);
    }
    if(doorDetectButton.contains(x, y)){
      doorDetectButton.setSelected(true);
    } else {
      doorDetectButton.setSelected(false);
    }
    if(rawViewButton.contains(x, y)){
      rawViewButton.setSelected(true);
    } else {
      rawViewButton.setSelected(false);
    }
  }
}

void onMousePressed(int button, int x, int y){
  if(videoSocket != null && button == MouseEvent.BUTTON3){
    // Since we keep the overlay stationary when moving the mouse, we need 
    // to store the initial mouse press location somewhere we can get to it.
    mouseDown = true;
    mouseDownX = x;
    mouseDownY = y;
  }
}

void onMouseReleased(int button, int x, int y){
  if(videoSocket != null && button == MouseEvent.BUTTON3){
    // User has released the mouse, so check to see if the mouse is on a button
    // and if it is, trigger the button's behavior.
    mouseDown = false;
    try{
      if(edgeDetectButton.isSelected()){
        println("Edge detection mode selected!");
        controlOutput.write("EDGE;".getBytes());
      } else if(doorDetectButton.isSelected()){
        println("Door detection mode selected!");
        controlOutput.write("DOOR;".getBytes());
      } else if(rawViewButton.isSelected()){
        println("Raw video mode selected!");
        controlOutput.write("RAW;".getBytes());
      }
      controlOutput.flush();
    } catch (IOException ioe){
      println("IOException occurred when trying to set mode.");
      // TODO look into printing an error message to GUI
    }
  }
}

void drawOverlayUi(int x, int y){
  // Draw me some buttons!
  edgeDetectButton.drawAt(x, y);
  doorDetectButton.drawAt(x, y);
  rawViewButton.drawAt(x, y);
}

/*
  Respond to keyboard input events.
*/
void keyTyped(){
  // It's always nice to be able to exit cleanly.
  if(key == ESC){
    cleanUp();
    exit();
  } 
  else if(key == 's' || key == 'S'){
    // Move backwards
    println("Moving backward 5cm.");
    try{
      controlOutput.write("MOVE -5;".getBytes());
    } catch (IOException ioe){
      println("Failed to send packet!");
    }
  }
  else if(key == 'w' || key == 'W'){
    // Move forwards.
    println("Moving forward 5cm.");
    try{
      controlOutput.write("MOVE 5;".getBytes());
    } catch (IOException ioe){
      println("Failed to send packet!");
    }
  }
}

/*
  Draw the connection UI using ControlP5.
*/
void drawConnectGui(){
  drawTitle();

  // Text buttons for connection type
  btButton = new TextButton("Bluetooth", start_x - 2, start_y - 35, 117, 25);
  btButton.setFont(dejavusans);
  btButton.setColors(unselectedTextColor, selectedTextColor);
  btButton.setSelected(true);

  netButton = new TextButton("Network", start_x + 128, start_y - 35, 25);
  netButton.setFont(dejavusans);
  netButton.setColors(unselectedTextColor, selectedTextColor);
  
  // Some GUI elements. The spacing here is important.
  addressField = controlP5.addTextfield("address", start_x, start_y, 140, 20);
  controlP5.addButton("connect", 1, start_x + 159, start_y, 70, 20);

  // Text area for status messages. Should be the same width as above controls.
  statusArea = controlP5.addTextarea("status", "", start_x, start_y + 50, 
                                     215, 300);
}

void drawTitle(){
 // Nice, beautiful title text!
  textMode(SCREEN);
  noSmooth();
  textFont(libertine);
  noStroke();
  fill(255);
  text("Pilot", start_x, start_y - 50);
}

/*
  Handle UI events generated by ControlP5.
*/
void controlEvent(ControlEvent ev){
  Controller controller = ev.controller();
  // We only have one button, so...
  if(controller.name().equals("connect")){
    connectToRobot();
  }
}

/*
  Connect to the robot over the network.
*/
void connectToRobot(){
  //  print("Trying to connect to robot...");
  String host = addressField.getText();
  try {
    displayStatus("Contacting rover.");
    videoSocket = new Socket(host, DEFAULT_VIDEO_PORT);
    controlSocket = new Socket(host, DEFAULT_CONTROL_PORT);
    displayStatus("Connection established!");
    videoInput = videoSocket.getInputStream();
    videoOutput = videoSocket.getOutputStream();
    controlInput = controlSocket.getInputStream();
    controlOutput = controlSocket.getOutputStream();
  }
  catch(Exception e){
    displayStatus("Failed to connect to " + host + "!");
  }
}

/* 
   Add a string to the status area.
*/
void displayStatus(String status){
  //  println(status);
  String current_text = statusArea.text();
  current_text += "\n" + status;
  statusArea.setText(current_text);
}

/*
  Request an image from the robot so we can display it.
*/
PImage requestImage(){
  // TODO Expand this to work with the real protocol.
  // Read the image from the network into a buffered image
  try{
    if(!image_request_pending){
      videoOutput.write("IMAGE;".getBytes());
      videoOutput.flush();
      image_request_pending = true;
    }

    if(videoInput.available() > 0){
      // Allocate more than we need into a flexible buffer.
      ByteBuffer buffer = ByteBuffer.allocate(2000*1100);
      while(videoInput.available() > 0){
        buffer.put((byte) videoInput.read());
      }

      InputStream imageBufferStream = new ByteArrayInputStream(buffer.array());
      BufferedImage image = ImageIO.read(imageBufferStream);

      // Since it's possible that we didn't get an image back, we'll check for
      // nulls.
      if(image != null){
        // Create a Processing-compatible image buffer for the read image...
        PImage pimage = new PImage(image.getWidth(), image.getHeight(), 
                                   PConstants.ARGB);
        // Read the buffered image's pixel data into the Processing-compatible buffer
        image.getRGB(0, 0, pimage.width, pimage.height, 
                     pimage.pixels, 0, pimage.width);
        pimage.updatePixels();
        image_request_pending = false;
        return pimage;
      } else {
        return null;
      }
    } else {
      return null;
    }
  } catch (IOException ioe){
    return null;
  }
}

/*
  Free up our network resources so we can close cleanly.
*/
void cleanUp(){
  if(videoSocket != null){
    try{
      videoOutput.write("QUIT;".getBytes());
      videoInput.close();
      videoOutput.close();
      videoSocket.close();
    } catch (IOException ioe){
      // Do nothing, since it doesn't matter; we're closing shop.
    }
  }
}

class OverlayButton {
  private int offsetX;
  private int offsetY;
  private int centerX;
  private int centerY;
  private PImage normalImage;
  private PImage selectedImage;
  private boolean selected = false;

  public OverlayButton(int offsetX, int offsetY, 
                       PImage normalImage, PImage selectedImage){
    this.offsetX = offsetX;
    this.offsetY = offsetY;
    this.selectedImage = selectedImage;
    this.normalImage = normalImage;
  }

  public void drawAt(int centerX, int centerY){
    this.centerX = centerX;
    this.centerY = centerY;
    imageMode(CENTER);
    if(selected){
      image(selectedImage, centerX + offsetX, centerY - offsetY);
    } else {
      image(normalImage, centerX + offsetX, centerY - offsetY);
    }
  }

  public void setSelected(boolean isSelected){
    selected = isSelected;
  }

  public boolean isSelected(){
    return selected;
  }

  private int quadrant(float angle){
    if(angle >= 0 && angle < HALF_PI) return 1;
    else if(angle >= HALF_PI && angle < PI) return 2;
    else if(angle >= PI && angle < PI + HALF_PI) return 3;
    else return 4;
  }

  public boolean contains(int x, int y){
    int dx = centerX - x;
    int dy = centerY - y;
    int adx = abs(dx);
    int ady = abs(dy);
    if(offsetX > 0 && dx < 0 && adx > ady){
      return true;
    } else if(offsetY < 0 && dy < 0 && ady > adx){
      return true;
    } else if(offsetX < 0 && dx > 0 && adx > ady){
      return true;
    } else if(offsetY > 0 && dy > 0 && ady > adx){
      return true;
    }
    return false;
  }
}

class TextButton {
  color textColor = color(255, 255, 255);
  color alternateColor = color(255, 255, 255);
  color backgroundColor = color(0, 0, 0);
  String buttonText;
  PFont font;
  float textX, textY, textW, textH;
  boolean selected = false;

  public TextButton(String text, float x, float y, float h){
    this.textX = x;
    this.textY = y;
    this.textW = textWidth(text);
    this.textH = h;
    buttonText = text;
  }

  public TextButton(String text, float x, float y, float w, float h){
    this.textX = x;
    this.textY = y;
    this.textW = w;
    this.textH = h;
    buttonText = text;
  }

  public void setColors(color main, color alternate, color background){
    textColor = main;
    alternateColor = alternate;
    backgroundColor = background;
  }

  public void setColors(color main, color alternate){
    textColor = main;
    alternateColor = alternate;
  }

  public void setFont(PFont font){
    this.font = font;
  }

  public void setText(String text){
    buttonText = text;
  }

  public boolean contains(int x, int y){
    if(mouseX >= textX && mouseX <= textX+textW){
      if(mouseY >= textY && mouseY <= textY+textH){
        return true;
      }
    }
    return false;
  }

  public boolean isSelected(){
    return selected;
  }

  public void setSelected(boolean isSelected){
    selected = isSelected;
  }

  public void draw(){
    noStroke();
    fill(backgroundColor);
    rect(textX, textY, textW, textH);
    textFont(font);
    if(this.isSelected()){
      fill(alternateColor);
    }
    else {
      fill(textColor);
    }
    text(buttonText, textX, textY, textW, textH);
  }
}