"""Network utilities for Python scripts."""

import socket

__author__ = "Nick Pascucci (npascut1@gmail.com)"

def get_ip_addr():
    """Resolve the network-facing IP address."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("gmail.com", 80))
    return s.getsockname()[0]
