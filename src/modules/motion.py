#! /usr/bin/env python

"""This module provides communications with an Arduino for motion control."""

import base64
import serial

__author__ = "Nick Pascucci (npascut1@gmail.com)"

class ArduinoMotionModule():
    # These must be defined to correspond with the values in motion_control.pde
    field_separator = ','
    command_separator = ';'
    SET_SPEED = '4'
    MOVE_DIST = '5'
    READ_SPEED = '6'
    READ_DIST = '7'
    ZERO_SERVOS = '8'
    ROTATE = '9'

    def __init__(self, port="/dev/ttyUSB0", baud=115200):
        return # Remove when actual communications are desired.
        self.port = port
        self.conn = serial.Serial(port, baud, timeout=1)

    def move(self, distance):
        """Move forward the specified distance in centimeters."""
        self.send(self.packetize(self.MOVE_DIST, self.encode_number(distance)))

    def rotate(self, angle):
        """Rotate through the specified angle in place.

        Positive values indicate a clockwise rotation, negative values
        counter-clockwise. Values should be specified in degrees."""
        self.send(self.packetize(self.ROTATE, self.encode_number(angle)))

    def packetize(self, command, *args):
        """Generate a wire-ready packet from the given arguments."""
        packet = command
        for arg in args:
            packet += "%s%s" % (self.field_separator, arg)
        packet += self.command_separator
        return packet

    def send(self, message):
        """Send a packet over the wire."""
        print "Sending message:", message
        return # Remove this when you want to actually send data.
        self.conn.write(message)
        
    def encode_number(self, num):
        """Encode a number into a wire-ready format."""
        charval = chr(num)
        return base64.b64encode(charval)

    def close(self):
        """Close the module and perform any clean up necessary."""
        pass
