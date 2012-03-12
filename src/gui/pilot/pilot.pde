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
// We'll use controlP5 for buttons and such; we'll need 3 of them.
ControlP5 netControlP5;
ControlP5 btControlP5;
ControlP5 sharedControlP5;
Button btConnectButton;

// This guy stores our network address.
Textfield addressField;

// Shared status area.
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
int DEFAULT_VIDEO_PORT = 9494;
int DEFAULT_CONTROL_PORT = 9495;
SocketAdapter videoChannel;
SocketAdapter controlChannel;

Bluetooth bt;
Client botVideoBt;
Client botControlBt;
String BT_VIDEO_SERVICE_NAME = "BotDriverVideo";
String BT_CONTROL_SERVICE_NAME = "BotDriverControl";

boolean image_request_pending = false;

void setup() {
  // General window setup.
  if(screenWidth < 1920) { // Detect large screens, and avoid overfilling
    size(screenWidth, screenHeight, P2D);
  } else {
    size(1280, 960, P2D);
  }
  frame.setTitle("Pilot");
  background(bgColor);

  // Typography! It's nice to have good fonts.
  libertine = loadFont("libertine-100.vlw");
  dejavusans = loadFont("dejavusans-24.vlw");

  // Set up listeners: one for motion, so we can detect drag events for
  // selecting overlay buttons; and one for press/release events to bring up the
  // overlay when the user presses the right mouse button.
  addMouseMotionListener(new MouseMotionListener() {
      public void mouseMoved(MouseEvent e) { }

      public void mouseDragged(MouseEvent e) {
        onMouseDragged(e.getButton(), e.getX(), e.getY());
      } 
    });

  addMouseListener(new MouseListener() {
      public void mouseClicked(MouseEvent e) { }
      public void mouseEntered(MouseEvent e) { }
      public void mouseExited(MouseEvent e) { }

      public void mousePressed(MouseEvent e) {
        onMousePressed(e.getButton(), e.getX(), e.getY());
      }
      public void mouseReleased(MouseEvent e) {
        onMouseReleased(e.getButton(), e.getX(), e.getY());
      }
    });

  // Initial GUI elements: we want consistent, parametric location; so we
  // pre-calculate the starting positions.
  start_x = (width - 220)/2;
  start_y = (height/2)+25;

  netControlP5 = new ControlP5(this);
  btControlP5 = new ControlP5(this);
  sharedControlP5 = new ControlP5(this);

  // We'll draw the GUI manually; otherwise, these will draw in weird ways.
  netControlP5.setAutoDraw(false);
  btControlP5.setAutoDraw(false);
  sharedControlP5.setAutoDraw(false);

  drawConnectGui();

  // Overlay buttons, for when we're connected to the robot.
  edgeDetectButton = new OverlayButton(this, -60, 0, loadImage("left_normal.png"), 
                                       loadImage("left_selected.png"));
  rawViewButton = new OverlayButton(this, 0, 60, loadImage("top_normal.png"), 
                                    loadImage("top_selected.png"));
  doorDetectButton = new OverlayButton(this, 60, 0, loadImage("right_normal.png"), 
                                       loadImage("right_selected.png"));
  
  // Create an RFCOMM Bluetooth object for carrying out BT scans
  try{
    bt = new Bluetooth(this, Bluetooth.UUID_L2CAP);
    bt.find();
    displayStatus("Beginning service discovery...");
  } catch (RuntimeException re){
    // Why they chose to use a RuntimeException here is beyond me.
    displayStatus("Unable to initiate Bluetooth scan.\n" 
                  + "Is everything turned on?");
    displayStatus(re.toString());
  }
}

void draw() {
  if(videoChannel != null) {
    // Connected to robot! Let's start getting some imagery.
    PImage pimage = requestImage();

    if(pimage != null) {
      if(imgScaleX == 0) {
        // We'll try to speed up the render with precomputed scaling/translation
        computeImageScaling(pimage.width, pimage.height);
      }
      noSmooth(); // Turn off smoothing for faster render.
      imageMode(CORNER);
      image(pimage, imgOffsetX, imgOffsetY, imgScaleX, imgScaleY);
    }

    // We need to check for the mouse being pressed in order to draw over
    // successive frames.
    if(mouseDown) {
      drawOverlayUi(mouseDownX, mouseDownY);
    }
  } else {
    // If we're not connected, we should draw a GUI to allow the user to do so.
    // background() will cover the entire frame in a solid color; black should
    // do nicely. Then we need to draw our title text and our two buttons, and
    // then check if we need to draw additional ControlP5 elements.
    background(0);
    drawTitle();
    if(botVideoBt == null || botControlBt == null){
      btButton.setEnabled(false);
    } else {
      btButton.setEnabled(true);
    }
      btButton.draw();
    netButton.draw();

    if(netButton.isSelected()) {
      addressField.setFocus(true);
      netControlP5.draw();
    }
    if(btButton.isSelected()) {
      if(botVideoBt == null || botControlBt == null){
        // If we don't have a Bluetooth connection available, we should indicate
        // that to the user. ControlP5 doesn't have a method to disable buttons
        // (which is ridiculous) so we'll just have to change the color.
        btConnectButton.setColorBackground(color(100));
        btConnectButton.setColorForeground(color(100));
      } else {
        
      }
      btControlP5.draw();
    }
    sharedControlP5.draw();
  }
}

/*
  Request an image from the robot so we can display it.
*/
PImage requestImage() {
  // TODO Expand this to work with the real protocol.
  // Read the image from the network into a buffered image
  if(!image_request_pending) {
    videoChannel.write("IMAGE;".getBytes());
    videoChannel.flush();
    image_request_pending = true;
  }

  if(videoChannel.available() > 0) {
    // The control channel should reply with a string specifying the number of
    // bytes to expect. We should wait until we've read all of them, otherwise
    // we'll get a rendering problem and a funky texture instead of a beautiful
    // image. 
    byte[] sizeString = new byte[20];
    int position = 0;
    byte lastReadByte = 'a';
    while(position < sizeString.length){
      lastReadByte = (byte) controlChannel.read();
      // Just like all other communications, this one is terminated with a
      // semicolon. We'll read all of the characters up to the semi, then exit
      // the loop.
      if(lastReadByte != ';'){
        sizeString[position] = lastReadByte;
        position++;
      } else {
        // Now we should get rid of the unnecessary bytes.
        byte[] tmp = new byte[position];
        System.arraycopy(sizeString, 0, tmp, 0, position);
        sizeString = tmp;
        break;
      }
    }

    // Great, we have the size! Now we need to parse it into a number.
    int numBytes = Integer.parseInt(new String(sizeString));

    ByteBuffer buffer = ByteBuffer.allocate(numBytes);
    int bytesRead = 0;

    while(bytesRead < numBytes) {
      // Ideally this should block until there's more data to read.
      buffer.put((byte) videoChannel.read());
      bytesRead++;
    }

    InputStream imageBufferStream = new ByteArrayInputStream(buffer.array());
    try {
      BufferedImage image = ImageIO.read(imageBufferStream);

      // Since it's possible that we didn't get an image back, we'll check for
      // nulls.
      if(image != null) {
        // Create a Processing-compatible image buffer for the read image...
        PImage pimage = new PImage(image.getWidth(), image.getHeight(), 
                                   PConstants.ARGB);
        // Read the buffered image's pixel data into the Processing buffer
        image.getRGB(0, 0, pimage.width, pimage.height, 
                     pimage.pixels, 0, pimage.width);
        pimage.updatePixels();
        image_request_pending = false;
        return pimage;
      } else {
        return null;
      }
    } catch (IOException ioe) {
      return null;
    }
  } else {
    return null;
  }
}

/*
  Generate an integer scaling factor for images. Using an integer scaling
  factor allows the system to very efficiently scale images by writing one
  pixel's value to n pixels, where n is the square of the scaling factor. This
  is much faster than trying to compute fractions of pixels and blend them.
*/
void computeImageScaling(int xSize, int ySize) {
  imgScaleX = xSize;
  imgScaleY = ySize;

  // While we're still in bounds, increase the image size.
  // This should only happen once, or maybe twice if the image is small.
  while(imgScaleX + xSize <= width && imgScaleY + ySize <= height) {
    imgScaleX += xSize;
    imgScaleY += ySize;
  }
  // Calculate the new offsets so we center the image properly.
  imgOffsetX = (width - imgScaleX) / 2;
  imgOffsetY = (height - imgScaleY) / 2;
}

/*
  Handle mouse click events.
 */
void mouseClicked() {
  // This event is only interesting if we're not connected to the robot; for
  // using the overlay buttons we need more fine grained control. However, for
  // general text buttons, this event is very useful; we'll check to see if the
  // mouse is in any of them and select them if so.
  if(videoChannel == null) {
    if(btButton.contains(mouseX, mouseY) && btButton.isEnabled()) {
      btButton.setSelected(true);
      netButton.setSelected(false);
    } else if (netButton.contains(mouseX, mouseY) && netButton.isEnabled()) {
      netButton.setSelected(true);
      btButton.setSelected(false);
    }
  }
}

/*
  Respond to mouse drag events by selecting overlay UI elements.
*/
void onMouseDragged(int button, int x, int y) {
  if(videoChannel != null && mouseDown) {
    // Connected to robot, so let's do some UI magic!
    // Check the location of the mouse and see if it's in any of our buttons.
    // If it is, highlight the button.
    if(edgeDetectButton.contains(x, y)) {
      edgeDetectButton.setSelected(true);
    } else {
      edgeDetectButton.setSelected(false);
    }

    if(doorDetectButton.contains(x, y)) {
      doorDetectButton.setSelected(true);
    } else {
      doorDetectButton.setSelected(false);
    }

    if(rawViewButton.contains(x, y)) {
      rawViewButton.setSelected(true);
    } else {
      rawViewButton.setSelected(false);
    }
  }
}

void onMousePressed(int button, int x, int y) {
  if(videoChannel != null && button == MouseEvent.BUTTON3) {
    // Since we keep the overlay stationary when moving the mouse, we need 
    // to store the initial mouse press location somewhere we can get to it.
    mouseDown = true;
    mouseDownX = x;
    mouseDownY = y;
  }
}

void onMouseReleased(int button, int x, int y) {
  if(videoChannel != null && button == MouseEvent.BUTTON3) {
    // User has released the mouse, so check to see if the mouse is on a button
    // and if it is, trigger the button's behavior.
    mouseDown = false;
    if(edgeDetectButton.isSelected()) {
      println("Edge detection mode selected!");
      controlChannel.write("EDGE;".getBytes());
    } else if(doorDetectButton.isSelected()) {
      println("Door detection mode selected!");
      controlChannel.write("DOOR;".getBytes());
    } else if(rawViewButton.isSelected()) {
      println("Raw video mode selected!");
      controlChannel.write("RAW;".getBytes());
    }
    controlChannel.flush();
  }
}

/*
  Draw the title text.
 */
void drawTitle() {
  // Nice, beautiful title text!
  textMode(SCREEN);
  noSmooth();
  textFont(libertine);
  noStroke();
  fill(255);
  text("Pilot", start_x, start_y - 50);
}

/*
  Draw the connection UI.
*/
void drawConnectGui() {
  drawTitle();

  // Text buttons for connection type
  btButton = new TextButton(this, "Bluetooth", 
                            start_x - 2, start_y - 35, 117, 25);
  btButton.setFont(dejavusans);
  btButton.setColors(unselectedTextColor, selectedTextColor);
  btButton.setSelected(false);

  netButton = new TextButton(this, "Network", start_x + 128, start_y - 35, 25);
  netButton.setFont(dejavusans);
  netButton.setColors(unselectedTextColor, selectedTextColor);
  netButton.setSelected(true);
  
  // Some GUI elements. The spacing here is important.
  addressField = netControlP5.addTextfield("address", start_x, start_y, 140, 20);
  netControlP5.addButton("connect", 1, start_x + 159, start_y, 70, 20);

  // We'll need a reference to this in order to change the color.
  btConnectButton = btControlP5.addButton("connect", 1, 
                                          start_x + 70, start_y, 70, 20);

  // Text area for status messages. Should be the same width as above controls.
  statusArea = sharedControlP5.addTextarea("status", "", start_x, start_y + 50, 
                                     215, 300);
}

/*
  When the user drags the mouse, draw an overlay button ring around it.
 */
void drawOverlayUi(int x, int y) {
  // Draw me some buttons!
  edgeDetectButton.drawAt(x, y);
  doorDetectButton.drawAt(x, y);
  rawViewButton.drawAt(x, y);
}

/*
  Respond to keyboard input events.
*/
void keyTyped() {
  // It's always nice to be able to exit cleanly.
  if(key == ESC) {
    cleanUp();
    exit();
  } 

  if(controlChannel != null){
    if(key == 's' || key == 'S') {
      // Move backwards
      println("Moving backward.");
      controlChannel.write("MOVE BACKWARD;".getBytes());
    } else if(key == 'w' || key == 'W') {
      // Move forwards.
      println("Moving forward.");
      controlChannel.write("MOVE FORWARD;".getBytes());
    } else if(key == 'a' || key == 'A') {
      // Move backwards
      println("Rotating left.");
      controlChannel.write("ROTATE COUNTERCLOCKWISE;".getBytes());
    } else if(key == 'd' || key == 'D') {
      // Move forwards.
      println("Rotating right.");
      controlChannel.write("ROTATE CLOCKWISE;".getBytes());
    }
  }
}

/*
  Handle UI events generated by ControlP5.
*/
void controlEvent(ControlEvent ev) {
  Controller controller = ev.controller();

  // We need to know which UI element fired this event. Both of our connect
  // buttons are named "connect" because controlP5 is weird; so we'll have to
  // take a look at our much more sane TextButtons.
  if(netButton.isSelected()){
    connectToRobotInternet();
  } else {
    connectToRobotBluetooth();
  }
}

/*
  Connect to the robot over the network.
*/
void connectToRobotInternet() {
  // User's in network connect mode, so we'll try to connect over the Internet
  String host = addressField.getText();
  displayStatus("Contacting rover.");
  try {
    InternetAdapter videoAdapter = new InternetAdapter(new Socket(host, 
                                                                  DEFAULT_VIDEO_PORT));
    InternetAdapter controlAdapter = new InternetAdapter(new Socket(host, 
                                                                    DEFAULT_CONTROL_PORT));
    videoAdapter.connect();
    controlAdapter.connect();

    videoChannel = videoAdapter;
    controlChannel = controlAdapter;
  } catch(UnknownHostException uhe) {
    displayStatus("Unknown host " + host);
  } catch(IOException ioe) {
    displayStatus("Error while trying to open sockets!");
  }
}

void connectToRobotBluetooth(){
  displayStatus("Trying to connect over Bluetooth.");
}

void serviceDiscoveryCompleteEvent(Service[] services){
  displayStatus("Service discovery complete.");
  displayStatus("Found " + services.length + " services.");
  for(Service service : services){
    displayStatus("INFO: found service " + service.name);
    if(service.name.equals(BT_VIDEO_SERVICE_NAME)){
      displayStatus("Found a BotDriver video service!");
      try {
        botVideoBt = service.connect();
      } catch (RuntimeException re){
        // Man, what's with all these RuntimeExceptions? They really want your
        // program to die, don't they?
        displayStatus("An error occurred while trying to contact the service.");
      }
    }

    if(service.name.equals(BT_CONTROL_SERVICE_NAME)){
      displayStatus("Found a BotDriver control service!");
      try {
        botControlBt = service.connect();
      } catch (RuntimeException re){
        displayStatus("An error occurred while trying to contact the service.");
        displayStatus(re.toString());
      }
    }
  }
  if(botVideoBt == null && botControlBt == null){
    displayStatus("Scan complete.");
  }
}

/* 
   Add a string to the status area.
*/
void displayStatus(String status) {
  //  println(status);
  String current_text = statusArea.text();
  current_text += "\n" + status;
  statusArea.setText(current_text);
}

/*
  Free up our network resources so we can close cleanly.
*/
void cleanUp() {
  if(videoChannel != null) {
    controlChannel.write("QUIT;".getBytes());
    videoChannel.close();
    controlChannel.close();
  }
}
