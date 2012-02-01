# Design Notes

## Overview

## Hardware Design

### 1) Structure

The system is designed to be constructed from a set of aluminum angle pieces fastened together into
a rectangular box configuration using 3D printed brackets. The source file for these brackets is
available in the draw/ directory. This configuration is straightforward to fabricate and offers
flexibility to the design, as well as an acceptable level of rigidity and ease of modification. 4-40
x 1/2" socket head screws are used as fasteners due to their high availability and their
standardization in mounting circuit boards. Mounting points are provided by additional 3D printed
parts and flat surfaces are fabricated from sheets of acrylic mounted to the frame.

### 2) Locomotion

Movement is accomplished through the use of full rotation servomotors. These motors allow the user
to set a constant angular velocity at the servo shaft via a PWM signal, and are thus useful for
robotics due to their lowered complexity of control. Custom brackets fabricated on a 3D printer are
used to fasten the motors to the frame, and they are controlled by an Arduino microcontroller to
provide a level of abstraction to the main navigation systems.

### 3) Sensing

The system is equipped with several sensors: first, a set of optical rotary encoders measures the
travel of each wheel and reports this data to the Arduino motor controller. This allows the motor
controller to maintain a constant velocity and to record the distance traveled by each wheel,
enabling dead-reckoning position estimates to be performed. Second, a powerful camera assembly is
mounted to the front frame of the robot which provides 640x480 pixel images for use in navigation
and object detection. Image data is transmitted over a serial communications link directly to the
PandaBoard controller, and images can be captured about once every 3 seconds.

### 4) Power Supply

Design of the power supply is ongoing... I've tried using a portable device charger to supply power
over USB, but the PandaBoard draws more current than it can provide and can't complete the boot
sequence. I may combine two such chargers to power the system.

## Software Design
   .......................       ......................
   .                     .       .    Internal        .
   . Input/Sensor Module .........   State Module     .
   .                     .       .  (Kalman Filter)   .
   .......................       ......................
             .                             .
             .                             .
   .......................       ......................         .......................
   .   World State       .       .   Decision         .         .     Actuator        .
   .    Module           .........    Module          ...........      Module         .
   .......................       ......................         .......................

## Notes

- The camera selected for this project was chosen due to its serial communications
  capabilities. Originally, the entire system was to be operated by a Parallax Propeller
  microcontroller; however, the computational requirements of computer vision proved to be too great
  for that system and it was decided to upgrade to a PandaBoard. By that time a camera had already
  been purchased, and the system has been designed to work with it.

