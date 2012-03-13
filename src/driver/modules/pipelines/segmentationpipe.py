"""An image processing pipeline stage which divides the image into segments."""

import cv
import itertools

__author__ = "Nick Pascucci (npascut1@gmail.com)"

class ShotgunSegmentationPipe:
    """An implementation of a simple flood fill image segmentor.

    This pipe can be used to simplify an image before other processing steps are
    applied; this is useful, for example, to improve the output of a
    detector. It works by initiating a flood fill at multiple points in the
    image, and filling those regions with the color of the starting pixel."""

    def __init__(self, next_pipe):
        self.next_pipe = next_pipe

    def process(self, image, x_points=8, y_points=6,
                max_difference=(1, 3, 3, 0), passes=1):
        # First, select the points we want. We should have x_points*y_points of
        # them, as they're the cross product of the x and y values.
        x_vals = [int((i + 0.5) * (image.width/x_points)) for i in range(x_points)]
        y_vals = [int((i + 0.5) * (image.height/y_points)) for i in range(y_points)]
        coordinates = list(itertools.product(x_vals, y_vals))

        for i in range(15):
            cv.Smooth(image, image)
        
        for i in range(passes):
            for coordinate in coordinates:
                x, y = coordinate
                # Remember, cv array access is wonky
                color = image[y, x]
                b, g, r = color
                cv.FloodFill(image, coordinate, color,
                             max_difference, max_difference)
                
        if self.next_pipe:
            processed_image = self.next_pipe.process(image)
            return processed_image
        else:
            return image
