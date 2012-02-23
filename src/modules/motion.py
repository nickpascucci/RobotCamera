#! /usr/bin/env python

"""This module provides communications with an Arduino for motion control."""

import base64
import serial

__author__ = "Nick Pascucci (npascut1@gmail.com)"

class ArduinoMotionModule():
    # These must be defined to correspond with the values in motion_control.pde
    field_separator = ','
    command_separator = ';'
    MOVE_DIST = '5'
    READ_DIST = '7'
    SET_SPEED = '4'
    READ_SPEED = '6'


    def __init__(self, port="/dev/ttyUSB0", baud=115200):
        self.port = port
        self.conn = serial.Serial(port, baud, timeout=1)

    def move(self, distance):
        """Move forward the specified distance in centimeters."""
        pass
        

    def rotate(self, angle):
        """Rotate through the specified angle in place.

        Positive values indicate a clockwise rotation, negative values
        counter-clockwise. Values should be specified in degrees."""
        pass

    def packetize(self, command, *args):
        packet = command
        for arg in args:
            packet += "%s%s" % (self.field_separator, arg)
        packet += self.command_separator

    def encode_number(self, num):
        charval = chr(num)
        return base64.b64encode(charval)

    def close(self):
        """Close the module and perform any clean up necessary."""
        pass
