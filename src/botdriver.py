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
        self.modules = {}
        self.modules["camera"] = CameraModule()
        self.modules["motion"] = ArduinoMotionModule()

    def wait_for_connections(self):
        """Open a server socket and wait for connections."""
        # Opening up to the world, we create a pair of server sockets.
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

        # Begin listening with no timeout, and get ready for incoming requests.
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
        # Get all of the sockets ready for reading using select()...
        rlist, wlist, xlist = select.select(
            [self.video_conn, self.control_conn], [], [])

        # Now, go through the list and execute commands from each socket.
        for connection in rlist:
            packet = connection.recv(4096)
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
                cam = self.modules["camera"]

                # Here, we capture an image from the webcam and write it to a
                # file.  Doing this much disk I/O slows downt this process
                # significantly, so it would be nice to store the image in
                # memory before we send it; unfortunately, the Python OpenCV
                # bindings don't allow us to use cv::imencode because there's no
                # Python equivalent to the C++ vector<uchar> type. It might be
                # worth writing our own wrapper function to speed this
                # up. Another idea is to try to short-circuit the cv.SaveImage
                # function to have it write to a StringIO buffer; but I have no
                # idea how to do that.
                # cam.capture_image_to_file("tmp.jpg")
                # image_file = open("tmp.jpg", "r")
                # self.video_conn.sendall(image_file.read())
                img = cam.capture_jpeg()
                self.video_conn.sendall(img)
            # Swapping video modes is pretty simple from this end...
            elif packet == "EDGE":
                cam = self.modules["camera"]
                cam.set_mode(CameraModule.EDGE_DETECT_MODE)
            elif packet == "RAW":
                cam = self.modules["camera"]
                cam.set_mode(CameraModule.RAW_VIDEO_MODE)
            elif packet == "DOOR":
                cam = self.modules["camera"]
                cam.set_mode(CameraModule.DOOR_DETECT_MODE)
            # as is directing movement.
            elif packet.startswith("MOVE"):
                packet_parts = packet.split()
                motion = int(packet_parts[1])
                self.modules["motion"].move(motion)
            elif packet.startswith("ROTATE"):
                packet_parts = packet.split()
                rotation = int(packet_parts[1])
                self.modules["motion"].rotate(rotation)

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
    
