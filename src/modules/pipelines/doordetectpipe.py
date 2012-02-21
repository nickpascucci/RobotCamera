"""An image processing pipeline stage which detects doors in the scene."""

__author__ = "Nick Pascucci (npascut1@gmail.com)"

class DoorDetectPipe:

    def __init__(self, next_pipe):
        self.next_pipe = next_pipe

    def process(self, image):
        # TODO Implement door detection.
        return image
        

