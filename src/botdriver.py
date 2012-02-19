#! /usr/bin/env python
# Robot driver program: receives commands from Pilot and executes them.

import socket
from util import netutils

DEFAULT_PORT = 9494

class BotDriver:
    def __init__(self):
        pass

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
        self.parse_and_execute(packet)

    def parse_and_execute(self, packet):
        pass

    def clean_up(self):
        self.conn.close()
        if self.socket: self.socket.close()

def main():
    bd = BotDriver()
    print "Bot driver up and waiting for connections."
    bd.wait_for_connections()
    while 1:
        bd.read_and_execute()

if __name__ == "__main__":
    main()
    
