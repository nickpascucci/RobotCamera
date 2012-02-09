# Performs an edge detection on an image using OpenCV.

import cv
import sys

original_img = cv.LoadImage(sys.argv[1], iscolor=cv.CV_LOAD_IMAGE_GRAYSCALE)
features = cv.CreateImage((original_img.width, original_img.height),
                          original_img.depth, original_img.nChannels)
cv.Canny(original_img, features, 70.0, 140.0)
cv.SaveImage(sys.argv[1] + "-features.jpg", features)

