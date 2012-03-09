# Performs an edge detection on an image using OpenCV.

import cv
import sys

# Load in the target image from the filesystem to an OpenCV IPL image
original_img = cv.LoadImage(sys.argv[1], iscolor=cv.CV_LOAD_IMAGE_GRAYSCALE)

# Create a new IPL image buffer for storing the edge detection result
features = cv.CreateImage((original_img.width, original_img.height),
                          original_img.depth, original_img.nChannels)

# Perform the edge detection into the features buffer
cv.Canny(original_img, features, 70.0, 140.0)

# Write out the resulting image.
cv.SaveImage(sys.argv[1] + "-features.jpg", features)

