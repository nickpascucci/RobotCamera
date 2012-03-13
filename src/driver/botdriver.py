#! /usr/bin/env python
# Robot driver program: receives commands from Pilot and executes them.

import sys
import os.path
from driver.modules import CameraModule, CameraError
from driver.modules import ArduinoMotionModule
from driver.modules import NetworkCommunicationsModule, BluetoothCommunicationsModule
try:
    import driver.settings as settings
except ImportError:
    # If we encounter an import error, we need to amend our path for the other
    # modules so they can import settings.
    sys.path.append(os.path.dirname(os.path.realpath(__file__)))
    import driver.settings as settings

class BotDriver:
    def __init__(self):
        # TODO Break all modules into their own threads and implement queues
        if settings.USE_BLUETOOTH:
            print "Bringing up Bluetooth interface..."
            self.comms = BluetoothCommunicationsModule()
        else:
            print "Bringing up network interface..."
            self.comms = NetworkCommunicationsModule()

        # If your video device is on a different /dev/ node, you need to modify
        # this to take that into account.
        self.camera = CameraModule()
        self.motion = ArduinoMotionModule()

        # TODO Perhaps we should break this out into an 'install()' method
        # or perform a list comprehension (use inheritence to define modules)
        self.installed_modules = [self.camera, self.motion, self.comms]

    def wait_for_connections(self):
        """Open a communications channel and wait for connections."""
        self.comms.wait_for_connections()

    def read_and_execute(self):
        """Read incoming commands and execute them."""
        for packet in self.comms.get_packets():
            self.parse_and_execute(packet)

    def parse_and_execute(self, packet_data):
        #print "Received packet", packet_data

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
                try:
                    img = self.camera.capture_jpeg()
                except CameraError:
                    print "An error occurred while trying to capture an image."
                    continue # Not much we can do about a camera error.
                self.comms.send_media(img)

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
                desired_motion = packet_parts[1]
                self.motion.move(desired_motion)
            elif packet.startswith("ROTATE"):
                packet_parts = packet.split()
                rotation = packet_parts[1]
                self.motion.rotate(rotation)

    def clean_up(self):
        """Free up module resources in preparation for closing."""
        for module in self.installed_modules:
            module.close()

def main():
    bluetooth = False
    port = "/dev/ttyUSB0"
    if len(sys.argv) > 1:
        for num, arg in enumerate(sys.argv):
            if arg == "-b":
                settings.USE_BLUETOOTH = True
            elif arg == "-p":
                print "Setting port."
                if len(sys.argv) > num+1:
                    settings.ARDUINO_PORT = sys.argv[num+1]
                else:
                    print "Expected port after '-p' argument."

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
