"""An image processing pipeline stage which performs edge detection."""

import cv

__author__ = "Nick Pascucci (npascut1@gmail.com)"

class EdgeDetectPipe:

    def __init__(self, next_pipe):
        self.next_pipe = next_pipe

    def process(self, image):
        grayscale = cv.CreateImage((image.width, image.height),
                                   image.depth, 1)
        features = cv.CreateImage((image.width, image.height),
                                  image.depth, 1)
        cv.CvtColor(image, grayscale, cv.CV_RGB2GRAY)
        cv.Canny(grayscale, features, 70.0, 140.0)
        if self.next_pipe:
            processed_image = self.next_pipe.process(features)
            return processed_image
        else:
            return features
        

