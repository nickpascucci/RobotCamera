#! /usr/bin/env python
# Robot driver program: receives commands from Pilot and executes them.

import select
import socket
import time
from modules import CameraModule
from util import netutils

DEFAULT_VIDEO_PORT = 9494
DEFAULT_CONTROL_PORT = 9495

class BotDriver:
    def __init__(self):
        self.modules = {}
        self.modules["camera"] = CameraModule()

    def wait_for_connections(self):
        """Open a server socket and wait for connections."""
        self.video_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.control_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        addr = netutils.get_ip_addr()
        
        # Video will always be sent on the video socket outbound channel.
        # Commands can be received on either socket; but it's generally a good
        # idea to stick to the command socket since that may change. Non-video
        # data will always go out on the command socket.
        self.video_socket.bind((addr, DEFAULT_VIDEO_PORT))
        self.control_socket.bind((addr, DEFAULT_CONTROL_PORT))

        print "Listening on %s." % (addr,)

        # For now, the order in which you connect is important.
        self.video_socket.listen(0)
        self.control_socket.listen(0)
        self.video_conn = None
        self.control_conn = None

        # We'll go ahead and wait for connections using select() so we can
        # accept connections in any order.
        available_sockets = [self.video_socket, self.control_socket]
        while self.video_conn == None or self.control_conn == None:
            rlist, wlist, xlist = select.select(
                available_sockets, [], [])
            for sock in rlist:
                if sock == self.video_socket:
                    self.video_conn, address = sock.accept()
                elif sock == self.control_socket:
                    self.control_conn, address = sock.accept()
                    print "Accepted connection from %s." % (address,)
                sock.close()
                available_sockets.remove(sock)
        
    def read_and_execute(self):
        """Read incoming commands from the network and execute them."""
        # Get all of the sockets ready for reading
        rlist, wlist, xlist = select.select(
            [self.video_conn, self.control_conn], [], [])

        # Now, go through the list and execute commands from each socket
        for connection in rlist:
            packet = connection.recv(4096)
            self.parse_and_execute(packet)

    def parse_and_execute(self, packet_data):
        print "Received packet", packet_data
        for packet in packet_data.split(";"):
            if packet == "QUIT":
                self.clean_up()
                exit(0)
            elif packet == "IMAGE":
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
                self.video_conn.sendall(image_file.read())
            elif packet == "EDGE":
                cam = self.modules["camera"]
                cam.set_mode(CameraModule.EDGE_DETECT_MODE)
            elif packet == "RAW":
                cam = self.modules["camera"]
                cam.set_mode(CameraModule.RAW_VIDEO_MODE)
            elif packet == "DOOR":
                cam = self.modules["camera"]
                cam.set_mode(CameraModule.DOOR_DETECT_MODE)

    def clean_up(self):
        """Free up network connections in preparation for closing."""
        self.video_conn.close()
        self.control_conn.close()

def main():
    bd = BotDriver()
    print "Bot driver up and waiting for connections."
    bd.wait_for_connections()
    while 1:
        bd.read_and_execute()

if __name__ == "__main__":
    main()
    
