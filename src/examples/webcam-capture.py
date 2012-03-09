# Capture an image from the first attached webcam.

import cv
import sys

# Create a CV capture object on the first available camera
capture = cv.CaptureFromCAM(0)
if not capture:
    print "Error opening camera."
    sys.exit(1)

cv.SetCaptureProperty(capture, cv.CV_CAP_PROP_FRAME_WIDTH, 640)
cv.SetCaptureProperty(capture, cv.CV_CAP_PROP_FRAME_HEIGHT, 480)

# Tell the capture device to grab a frame and return it.
# To synchronize multiple cameras, use GrabFrame() followed by RetrieveFrame()
image = cv.QueryFrame(capture)

# Save the image to the filesystem.
if image:
    cv.SaveImage(sys.argv[1], image)
