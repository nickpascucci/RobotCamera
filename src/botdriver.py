#! /usr/bin/env python
# Robot driver program: receives commands from Pilot and executes them.

import select
import socket
import time
from modules import CameraModule
from modules import ArduinoMotionModule
from util import netutils

DEFAULT_VIDEO_PORT = 9494
DEFAULT_CONTROL_PORT = 9495

class BotDriver:
    def __init__(self):
        # TODO Break all modules into their own threads and implement queues
        self.camera = CameraModule()
        self.motion = ArduinoMotionModule()
        self.comms = NetworkCommunicationsModule()
        # TODO Perhaps we should break this out into an 'install()' method
        # or perform a list comprehension (use inheritence to define modules)
        self.installed_modules = [self.camera, self.motion, self.comms]

    def wait_for_connections(self):
        """Open a communications channel and wait for connections."""
        self.comms.wait_for_connections()

    def read_and_execute(self):
        """Read incoming commands and execute them."""
        for packet in self.comms.get_packet():
            self.parse_and_execute(packet)

    def parse_and_execute(self, packet_data):
        print "Received packet", packet_data
        # TCP is a streaming protocol, which means that we can't rely on our
        # packets coming nice and orderly and one at a time. We have to
        # implement some structure on top of the stream to do that; the simplest
        # way is to simply add delimiters between requests. Fortunately, Pilot
        # implements a little bit of flow control for image requests on its
        # side.
        for packet in packet_data.split(";"):
            if packet == "QUIT":
                self.clean_up()
                exit(0)
            elif packet == "IMAGE":
                img = self.camera.capture_jpeg()
                self.video_conn.sendall(img)

            # Swapping video modes is pretty simple from this end...
            elif packet == "EDGE":
                self.camera.set_mode(CameraModule.EDGE_DETECT_MODE)
            elif packet == "RAW":
                self.camera.set_mode(CameraModule.RAW_VIDEO_MODE)
            elif packet == "DOOR":
                self.camera.set_mode(CameraModule.DOOR_DETECT_MODE)
            # as is directing movement.
            elif packet.startswith("MOVE"):
                packet_parts = packet.split()
                desired_motion = int(packet_parts[1])
                self.motion.move(desired_motion)
            elif packet.startswith("ROTATE"):
                packet_parts = packet.split()
                rotation = int(packet_parts[1])
                self.motion.rotate(rotation)

    def clean_up(self):
        """Free up network connections in preparation for closing."""
        if self.video_conn:
            self.video_conn.close()
        if self.control_conn:
            self.control_conn.close()
        # Don't forget the modules; they may have resources that need to be
        # freed before we can exit cleanly.
        for module in self.modules.itervalues():
            module.close()

def main():
    bd = BotDriver()
    try:
        print "Bot driver up and waiting for connections."
        bd.wait_for_connections()
        while 1:
            bd.read_and_execute()
    except KeyboardInterrupt:
        # The user can kill the program by pressing Ctrl-C, but when they do we
        # may have some resources open that we want to close. Catching this
        # exception and re-raising it allows us to do that and exit cleanly.
        bd.clean_up()
        exit(0)


if __name__ == "__main__":
    main()
    
