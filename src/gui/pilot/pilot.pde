/*
  Processing-based GUI for controlling the rover.
*/

import controlP5.*;
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
color bgColor = color(0, 0, 0);
PFont libertine;
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
int DEFAULT_PORT = 9494;
Socket socket;
InputStream input;
OutputStream output;

void setup(){
  // General window setup
  size(1280, 720, P2D);
  frame.setTitle("Pilot");
  background(bgColor);

  // Typography
  libertine = loadFont("libertine-100.vlw");

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
  if(socket != null){
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
    controlP5.draw();
  }
}

/*
  Generate an optimal scaling factor by successive doubling.
 */
void computeImageScaling(int xSize, int ySize){
  imgScaleX = xSize;
  imgScaleY = ySize;

  // While we're still in bounds, double the image size.
  // This should only happen once, or maybe twice if the image is small.
  while(2 * imgScaleX < width && 2 * imgScaleY < height){
    imgScaleX *= 2;
    imgScaleY *= 2;
  }
  // Calculate the new offsets so we center the image properly.
  imgOffsetX = (width - imgScaleX) / 2;
  imgOffsetY = (height - imgScaleY) / 2;
}

/*
  Respond to mouse input events.
 */
void onMouseDragged(int button, int x, int y){
  if(socket != null && mouseDown){
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
  if(socket != null && button == MouseEvent.BUTTON3){
    // Since we keep the overlay stationary when moving the mouse, we need 
    // to store the initial mouse press location somewhere we can get to it.
    mouseDown = true;
    mouseDownX = x;
    mouseDownY = y;
  }
}

void onMouseReleased(int button, int x, int y){
  if(socket != null && button == MouseEvent.BUTTON3){
    // User has released the mouse, so check to see if the mouse is on a button
    // and if it is, trigger the button's behavior.
    mouseDown = false;
    try{
      if(edgeDetectButton.isSelected()){
        println("Edge detection mode selected!");
        output.write("EDGE;".getBytes());
      } else if(doorDetectButton.isSelected()){
        println("Door detection mode selected!");
        output.write("DOOR;".getBytes());
      } else if(rawViewButton.isSelected()){
        println("Raw video mode selected!");
        output.write("RAW;".getBytes());
      }
      output.flush();
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
}

/*
  Draw the connection UI using ControlP5.
 */
void drawConnectGui(){
  // Nice, beautiful title text!
  textFont(libertine);
  noSmooth();
  text("Pilot", start_x, start_y - 25);

  // Some GUI elements... The spacing here is important.
  addressField = controlP5.addTextfield("address", start_x, start_y, 140, 20);
  controlP5.addButton("connect", 1, start_x + 155, start_y, 70, 20);

  // Text area for status messages. Should be the same width as above controls.
  statusArea = controlP5.addTextarea("status", "", start_x, start_y + 50, 
                                     215, 300);
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
    socket = new Socket(host, DEFAULT_PORT);
    socket.setTcpNoDelay(true); // This is gross and irresponsible, but needed
    displayStatus("Connection established!");
    input = socket.getInputStream();
    output = socket.getOutputStream();
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
    output.write("IMAGE;".getBytes());
    output.flush();
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

/*
  Free up our network resources so we can close cleanly.
 */
void cleanUp(){
  if(socket != null){
    try{
      output.write("QUIT;".getBytes());
      input.close();
      output.close();
      socket.close();
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