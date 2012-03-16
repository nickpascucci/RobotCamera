"""A pipeline stage which runs the image through GoodFeaturesToTrack."""

import cv

__author__ = "Nick Pascucci (npascut1@gmail.com)"

class GoodFeaturesPipe:

    def __init__(self, next_pipe):
        self.next_pipe = next_pipe

    def process(self, image, features=20, color=(255, 0, 0)):
        # The image needs to be in the right format, so convert it.
        new_image = cv.CreateMat(image.height, image.width, cv.CV_8UC1)
        cv.CvtColor(image, new_image, cv.CV_RGB2GRAY)
        image = new_image

        
        # This is straight out of the cookbook.
        eig_image = cv.CreateMat(image.height, image.width, cv.CV_32FC1)
        temp_image = cv.CreateMat(image.height, image.width, cv.CV_32FC1)

        for x, y in cv.GoodFeaturesToTrack(image, eig_image, temp_image,
                                             features, 0.04,
                                             1.0, useHarris=True):
            cv.Circle(image, (int(x), int(y)), 1, color)

        if self.next_pipe:
            processed_image = self.next_pipe.process(image)
            return processed_image
        else:
            return image
        

