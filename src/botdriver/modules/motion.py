#! /usr/bin/env python

"""This module provides communications with an Arduino for motion control."""

import base64
import serial

__author__ = "Nick Pascucci (npascut1@gmail.com)"

class ArduinoMotionModule():
    # These must be defined to correspond with the values in motion_control.pde
    ROTATE_CW = 'r'
    ROTATE_CCW = 'l'
    FORWARD = 'f'
    BACKWARD = 'b'
    CALIBRATE = 'c'
    STOP = 's'
    
    def __init__(self, port="/dev/ttyUSB0", baud=115200):
        return # Remove when actual communications are desired.
        self.port = port
        self.conn = serial.Serial(port, baud, timeout=1)

    def move(self, direction):
        """Move in the given direction."""
        if direction == "FORWARD":
            self.send(self.FORWARD)
        elif direction == "BACKWARD":
            self.send(self.BACKWARD)
        else:
            print "Unkown movement command ", direction

    def rotate(self, direction):
        """Rotate in the given direction."""
        if direction == "CLOCKWISE":
            self.send(self.ROTATE_CW)
        elif direction == "COUNTERCLOCKWISE":
            self.send(self.ROTATE_CCW)
        else:
            print "Unkown movement command ", direction
        
    def send(self, message):
        """Send a packet over the wire."""
        print "Sending message:", message
        return # Remove this when you want to actually send data.
        self.conn.write(message)
        
    def close(self):
        """Close the module and perform any clean up necessary."""
        pass
