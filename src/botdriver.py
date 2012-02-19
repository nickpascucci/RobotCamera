#! /usr/bin/env python
# Robot driver program: receives commands from Pilot and executes them.

import socket
from modules import CameraModule
from util import netutils

DEFAULT_PORT = 9494

class BotDriver:
    def __init__(self):
        self.modules = {}
        self.modules["camera"] = CameraModule()

    def wait_for_connections(self):
        """Open a server socket and wait for connections."""
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        addr = netutils.get_ip_addr()
        self.socket.bind((addr, DEFAULT_PORT))
        print "Listening on %s." % (addr,)
        self.socket.listen(0)
        (conn, address) = self.socket.accept()
        print "Accepted connection from %s." % (address,)
        self.conn = conn
        self.socket.close()
        
    def read_and_execute(self):
        """Read incoming commands from the network and execute them."""
        packet = self.conn.recv(4096)
        print "Received", packet
        self.parse_and_execute(packet)

    def parse_and_execute(self, packet):
        if packet == "QUIT":
            self.clean_up()
            exit(0)
        elif packet == "IMAGE":
            print "Sending image to remote host.",
            cam = self.modules["camera"]

            # Here, we capture an image from the webcam and write it to a file.
            # Doing this much disk I/O slows downt this process significantly,
            # so it would be nice to store the image in memory before we send
            # it; unfortunately, the Python OpenCV bindings don't allow us to
            # use cv::imencode because there's no Python equivalent to the C++
            # vector<uchar> type. It might be worth writing our own wrapper
            # function to speed this up. Another idea is to try to short-circuit
            # the cv.SaveImage function to have it write to a StringIO buffer;
            # but I have no idea how to do that.
            cam.capture_image_to_file("tmp.jpg")
            image_file = open("tmp.jpg", "r")
            self.conn.sendall(image_file.read())
            print "Done!"

    def clean_up(self):
        """Free up network connections in preparation for closing."""
        self.conn.close()
        if self.socket:
            self.socket.close()

def main():
    bd = BotDriver()
    print "Bot driver up and waiting for connections."
    bd.wait_for_connections()
    while 1:
        bd.read_and_execute()

if __name__ == "__main__":
    main()
    
