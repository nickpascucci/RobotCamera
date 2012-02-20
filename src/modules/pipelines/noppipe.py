#! /usr/bin/env python

"""An image processing pipeline stage which does nothing."""

__author__ = "Nick Pascucci (npascut1@gmail.com)"

class NopPipe:

    def __init__(self, next_pipe):
        self.next_pipe = next_pipe

    def process(self, image):
        return image
        

