#! /usr/bin/python

from modules import CameraModule
import cv
import sys

print "Loading up camera module."

cam = CameraModule()

print "Module loaded."
cam.set_mode(CameraModule.DOOR_DETECT_MODE)

print "Door detect mode enabled."

image = cv.LoadImage(sys.argv[1])
image = cam.pass_to_pipeline(image)
cv.SaveImage("camtest-out.png", image)

print "Image captured!"
