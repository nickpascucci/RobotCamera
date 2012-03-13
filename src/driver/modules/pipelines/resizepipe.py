"""An image processing pipeline stage which resizes images.

Using this pipe negates the need for setting resolution directly on the camera,
while still allowing for tuning of the received images. If you encounter a
problem with "Inappropriate IOCTL for device", you might consider using the
default camera resolution and resizing images as needed afterwards."""

import cv

__author__ = "Nick Pascucci (npascut1@gmail.com)"

class ResizePipe:

    def __init__(self, next_pipe, x_res=640, y_res=480):
        self.next_pipe = next_pipe
        self.x_res = x_res
        self.y_res = y_res

    def process(self, image):
        if image.width == self.x_res and image.height == self.y_res:
            return image

        # Resizing tries to fit the original image into the new destination
        # image exactly, so if they don't scale well to each other there may be
        # distortion.
        if ((image.width % self.x_res != 0 and self.x_res % image.width != 0) or
            (image.height % self.y_res != 0 and self.y_res % image.height != 0)):
                print ("WARNING: Resize target size does not fit cleanly into "
                       " original. Distortion of the image may occur.")
                print "\tOriginal size: %sx%s" % (image.width, image.height)
                print "\tTarget size: %sx%s" % (self.x_res, self.y_res)

        # We first create a destination image of the proper size,
        # and then call resize() with it to resize the image.
        # cv.CreateMat is kind of weird since it takes rows then columns as
        # arguments rather than the usual (x, y) ordering.
        if type(image) == cv.iplimage:
            resized_image = cv.CreateImage((self.x_res, self.y_res),
                                           image.depth, image.nChannels)
        else:
            resized_image = cv.CreateMat(self.y_res, self.x_res, image.type)
        cv.Resize(image, resized_image)

        if self.next_pipe:
            processed_image = self.next_pipe.process(resized_image)
            return processed_image
        else:
            return resized_image
