"""BotDriver module designed to handle input from a webcam."""

import cv
from pipelines import *

__author__ = "Nick Pascucci (npascut1@gmail.com)"

class CameraError(Exception):
    pass

class CameraModule:
    RAW_VIDEO_MODE = 0
    EDGE_DETECT_MODE = 1
    DOOR_DETECT_MODE = 2
    
    def __init__(self, camera=-1):
        self.capture = cv.CaptureFromCAM(camera)
        self.set_mode(self.RAW_VIDEO_MODE)
        
    def capture_image_to_file(self, filename):
        """Capture an image and write it to a file."""
        image = self.capture_image()
        cv.SaveImage(filename, image)

    def capture_image(self):
        """Capture and process an image from the webcam."""
        image = cv.QueryFrame(self.capture)
        if not image:
            raise CameraError("Failed to capture image!")
        image = self.pass_to_pipeline(image)
        return image        

    def capture_jpeg(self):
        """Capture an image from the webcam and return it encoded as a JPEG."""
        image = self.capture_image()
        jpeg = cv.EncodeImage('.jpeg', image)
        return jpeg.tostring()
        
    def pass_to_pipeline(self, image):
        """Perform preprocessing on the image by passing it to a pipeline."""
        processed_image = self.first_pipe.process(image)
        return processed_image

    def set_mode(self, mode):
        """Set the video pipeline mode for this camera module."""
        if mode == self.RAW_VIDEO_MODE:
            print "Setting up raw video pipeline."
            self.first_pipe = ResizePipe(None)
        elif mode == self.EDGE_DETECT_MODE:
            print "Setting up edge detection pipeline."
            last_pipe = ResizePipe(None)
            self.first_pipe = EdgeDetectPipe(last_pipe)
        elif mode == self.DOOR_DETECT_MODE:
            print "Setting up door detection pipeline."
            last_pipe = ResizePipe(None)
            second_pipe = DoorDetectPipe(last_pipe)
            self.first_pipe = EdgeDetectPipe(second_pipe)

    def close(self):
        """Close the module and perform any clean up necessary."""
        pass
