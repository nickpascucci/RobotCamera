"""BotDriver module for handling communications.

This module provides two methods for communications: Bluetooth and Network.
Bluetooth, as the name implies, communicates over a short-range radio link
directly with the Pilot program. Network talks over TCP, using whatever link is
available at the time."""

import bluetooth
import select
import socket
import uuid
from util import netutils
import driver.settings as settings

__author__ = "Nick Pascucci (npascut1@gmail.com)"

class NetworkCommunicationsModule:
    """An interface to standard TCP/IP network communications links."""

    DEFAULT_VIDEO_PORT = 9494
    DEFAULT_CONTROL_PORT = 9495

    def __init__(self):
        # Opening up to the world, we create a pair of server sockets.
        self.video_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.control_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.addr = netutils.get_ip_addr()

        # Video will always be sent on the video socket outbound channel.
        # Commands can be received on either socket; but it's generally a good
        # idea to stick to the command socket since that may change. Non-video
        # data will always go out on the command socket.
        self.video_socket.bind((self.addr, self.DEFAULT_VIDEO_PORT))
        self.control_socket.bind((self.addr, self.DEFAULT_CONTROL_PORT))

    def wait_for_connections(self):
        # Begin listening with no timeout, and get ready for incoming requests.
        self.video_socket.listen(0)
        self.control_socket.listen(0)
        self.video_conn = None
        self.control_conn = None

        print "Listening on %s." % (self.addr,)

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

    def get_packets(self):
        """Return all packets from the network interface."""
        # Get all of the sockets ready for reading using select()...
        rlist, wlist, xlist = select.select(
            [self.video_conn, self.control_conn], [], [])

        packets = []

        # Now, go through the list and execute commands from each socket.
        for connection in rlist:
            packet = connection.recv(4096)
            packets.append(packet)

        return packets

    def send_command(self, command):
        """Send data using the command channel."""
        self.control_conn.sendall(command)

    def send_media(self, media):
        """Send data using the media channel."""
        # The first thing we expect on the receive side is a string containing
        # the length of the media file, followed by a semicolon.
        self.control_conn.sendall("%s;" % len(media))
        self.video_conn.sendall(media)

    def close(self):
        """Close the module and perform any clean up necessary."""
        if self.video_conn:
            self.video_conn.close()
        if self.control_conn:
            self.control_conn.close()

            
class BluetoothCommunicationsModule:
    """An interface to Bluetooth radio links."""
    UUID = 'c917b21c-492f-4cb6-bc87-77f4031b88af'

    def __init__(self, service_name = "BotDriver"):
        self.video_socket = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
        self.control_socket = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
        self.video_socket.bind(("", bluetooth.PORT_ANY))
        self.control_socket.bind(("", bluetooth.PORT_ANY))

    def wait_for_connections(self):
        self.video_socket.listen(1)
        self.control_socket.listen(1)
        video_port = self.video_socket.getsockname()[1]
        control_port = self.control_socket.getsockname()[1]
        
        self.video_conn = None
        self.control_conn = None

        print "Listening on bluetooth."
        print "Video channel: %s" % (video_port,)
        print "Control channel: %s" % (control_port,)
        
        try:
            bluetooth.advertise_service(self.video_socket, "BotDriverVideo")
        except bluetooth.btcommon.BluetoothError:
            print ("Failed to advertise service. "
                   "Is the Bluetooth daemon running?")

        # We'll go ahead and wait for connections using select() so we can
        # accept connections in any order.
        available_sockets = [self.video_socket, self.control_socket]
        while self.video_conn == None or self.control_conn == None:
            rlist, wlist, xlist = select.select(
                available_sockets, [], [])
            for sock in rlist:
                if sock == self.video_socket:
                    self.video_conn, address = sock.accept()
                    sock.close()
                    print "Accepted connection from %s." % (address,)
                elif sock == self.control_socket:
                    self.control_conn, address = sock.accept()
                    sock.close()
                    print "Accepted connection from %s." % (address,)
                available_sockets.remove(sock)

    def get_packets(self):
        """Return all of the packets from the Bluetooth interface."""
        rlist, wlist, xlist = select.select(
            [self.video_conn, self.control_conn], [], [])

        packets = []

        for connection in rlist:
            packet = connection.recv(4096)
            packets.append(packet)

        return packets

    def send_command(self, command):
        self.control_conn.sendall(command)

    def send_media(self, media):
        self.video_conn.sendall(media)

    def close(self):
        """Close the module and perform any clean up necessary."""
        self.video_conn.close()
        self.control_conn.close()
