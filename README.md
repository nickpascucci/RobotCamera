## Robot Camera

# Overview
This project is aimed at creating a simple rover robot which can use a camera to
identify navigational cues and interesting features when negotiating a maze.

The project consists of a) a set of CAD files used for fabricating the robot's
chasis, and b) source code for motion control, vision, remote operation, and
autonomous navigation.

# Bill of Materials
### Parts:
4 8"x0.75" aluminum right angle extrusion
8 4"x0.75" aluminum right angle extrusion
84 M2.5 x 10 Socket head cap screws
8 M2.5 x 20 Socket head cap screws
92 M2.5 Nuts
1 PandaBoard, with SD card
1 Arduino
2 Continuous rotation servos
2 P1230 Photogates & supporting hardware (refer to your photogate's datasheet.)
1 USB webcam (I used a V7 CS2021.)

### Tools:
3D printer (I recommend using FDM'd ABS for this for its mechanical qualities.)
Drill press
Soldering iron
Tweezers (highly recommended for both soldering and tightening fasteners.)

# How to build this crazy thing
Ok, so you want to build your own robot. How do you get started?

### Structure
First, you're going to need a chasis. There's no reason you have to use mine
versus building your own, but in case you do, all the files you need should be
in the *draw/* directory. All of the parts except for angle aluminum and
fasteners are available as .stl meshes, ready and tested for 3D printing. Most
are also provided as STEP files that can be imported into all major CAD systems
and modified to suit your needs. You'll also need to cut and drill some pieces
of angle aluminum to serve as the primary structural members. I've included
drawings of these parts to give you the right dimensions. All of it goes
together as an assembly as detailed in the assembly.pdf drawing.

### Motion
Great, you have a chassis to hold everything in place. Now you're going to need
some electronics to drive it! The "ServoBracket.{step, stl}" parts are designed
to hold a standard size servo. Of course, a standard servo won't work for
turning wheels; you'll need continuous rotation ones. Mount two of them in the
brackets. In order to keep track of distance traveled and current speed
settings, you'll need to have some kind of encoder on your wheels. I designed a
3D-printable encoder wheel that sits between the servo and the drive wheel. It's
designed to fit into a P1230 photogate, though it should fit others as
well. These can be slotted into the smaller holes on the servo bracket and glued
into place with a 2-part epoxy. Connect the servos and photogates to an Arduino,
modify the firmware to match your pin choices, and upload the
firmware. Congrats, you have a simple motion control system!

### Intelligence
Next comes the brains of the operation. I assume that you made 3 of the board
mount assemblies; if not, do so now. These have little arms that rotate to meet
up with holes in the PandaBoard. Mount your board in the most convenient
orientation; I decided to put the USB ports forward. Attach the Arduino via USB
to the board, and do the same for your webcam. There is a part for mounting a V7
webcam to the chasis; if you have a similar device it should work well, and if
not you'll have to design your own. Attach your webcam to the chasis.

### Software
All right, that just about covers the hardware! Next step, software.

I'll assume that you have a working Linux distribution on your
PandaBoard. You're going to need to install Python (2.7 is preferred), OpenCV
and its Python bindings, PySerial, and Git. Clone this repo onto the PandaBoard,
check that settings.py reflects your configuration, and start up BotDriver. It
will attach to the network interface and wait for a connection from Pilot. On
your control machine, start a Processing session and initiate a Pilot run. Enter
the IP address of the robot and hit "Connect". If everything's working, it
should start feeding you video and relaying your commands to the robot. If not,
something went wrong; look at the output of both Pilot and BotDriver to see if
either of them has any useful information. If not, feel free to get in contact
with me.

## Misc

I'm open to incorporating updates or changes to any of this software/hardware;
if you make any improvements, I'd love to hear about them! If they have any
chance of being useful for other people, send me a pull request and I'll try and
merge them.

## Wishlist
See the issue tracker.

## LICENSE
All of the code in this repository is free software, licensed under the GNU
GPL. If you'd like an alternative license, contact me and we'll work something
out. 
