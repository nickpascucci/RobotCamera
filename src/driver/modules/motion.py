#! /usr/bin/env python
"""This module provides communications with an Arduino for motion control."""

import serial
import time
import driver.settings as settings

__author__ = "Nick Pascucci (npascut1@gmail.com)"

class ArduinoMotionModule():
    # These must be defined to correspond with the values in motion_control.pde
    ROTATE_CW = 'r'
    ROTATE_CCW = 'l'
    FORWARD = 'f'
    BACKWARD = 'b'
    CALIBRATE = 'c'
    STOP = 's'

    def __init__(self):
        self.port = settings.ARDUINO_PORT
        self.baud = settings.ARDUINO_BAUD
        self._connect()

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
        try:
            self.conn.write(message)
        except serial.SerialException as se:
            print "Caught SerialException. Attempting to reconnect in 1 second."
            time.sleep(1)
            self._connect()
            # We'll try to resend the message once we're connected. If this
            # fails, we'll just have to die from the exception.
            self.conn.write(message)

    def close(self):
        """Close the module and perform any clean up necessary."""
        pass

    def _connect(self):
        self.conn = serial.Serial(self.port, self.baud, timeout=1)
