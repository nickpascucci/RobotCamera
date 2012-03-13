"""An image processing pipeline stage which does nothing."""

__author__ = "Nick Pascucci (npascut1@gmail.com)"

class NopPipe:

    def __init__(self, next_pipe):
        self.next_pipe = next_pipe

    def process(self, image):
        if self.next_pipe:
            processed_image = self.next_pipe.process(image)
            return processed_image
        else:
            return image
