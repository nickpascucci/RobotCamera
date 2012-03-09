"""An image processing pipeline stage which detects doors in the scene."""

import cv

__author__ = "Nick Pascucci (npascut1@gmail.com)"

class DoorDetectError(Exception):
    pass

class ScanningDoorDetectPipe:
    """An implementation of a simple barscan door detector.

    This detector expects to be called on an edge-detected image."""

    def __init__(self, next_pipe):
        self.next_pipe = next_pipe

    def process(self, image):
        # First thing's first: we need to get sums for each row and column in
        # the image.
        # TODO Implement parameterization of the bar width
        row_sums = []
        col_sums = []

        # Vertical scan: look at each row and sum it.
        # OpenCV matrices are a pain because they're not iterable; I wrote a
        # method to sum them up to make life a little easier.
        for row in range(image.height):
            row_sums.append(self.sum_cvmat(image[row]))

        # Horizontal scan. As the image is stored in rows, we need to take the
        # nth element from each row in order to form a column. Just a little
        # more work than the vertical scan.
        for col in range(image.width):
            col_sums.append(self.sum_cvmat(image[:, col]))

        # We want the index of the largest 2 elements of our sum list.
        # I don't feel like writing a max function, so...
        max_col_1 = max(enumerate(col_sums), key=lambda elem: elem[1])[0]

        # Ok, now remove the maximum and go get the second-largest.
        col_sums[max_col_1] = 0
        max_col_2 = max(enumerate(col_sums), key=lambda elem: elem[1])[0]

        # Rinse, repeat for rows.
        max_row_1 = max(enumerate(row_sums), key=lambda elem: elem[1])[0]
        row_sums[max_row_1] = 0
        max_row_2 = max(enumerate(row_sums), key=lambda elem: elem[1])[0]

        # We'll build a couple of tuples specifying the corners for our
        # convenience here. Keep in mind these are the row/column numbers.
        top_left = (min(max_col_1, max_col_2), max(max_row_1, max_row_2))
        bottom_right = (max(max_col_1, max_col_2), min(max_row_1, max_row_2))

        print "Door detected at %s,%s" % (top_left, bottom_right)

        image = self.grayscale_to_color(image)
        
        # Now that we know where the door is in the image, we'll highlight it.
        # This is supposed to be red; I guess OpenCV uses BGR instead of RGB.
        cv.Rectangle(image, top_left, bottom_right, cv.Scalar(0, 0, 255))
        return image

    def sum_cvmat(self, cvmat, channel=0):
        """Sum a one-dimensional cvmat instance.

        Sums the values for the given channel of a cvmat for which either the
        number of rows or the number of columns is 1."""
        if cvmat.rows > 1 and cvmat.cols > 1:
            raise DoorDetectError("Array is not one dimensional.")

        if type(cvmat[0,0]) is tuple:
            if cvmat.rows > 1:
                # We want to get the specified channel for each row in the cvmat.
                return sum([cvmat[i, 0][channel] for i in range(cvmat.rows)])
            elif cvmat.cols > 1:
                return sum([cvmat[0, i][channel] for i in range(cvmat.cols)])

        elif type(cvmat[0,0]) is float:
            if cvmat.rows > 1:
                # We want to get the specified channel for each row in the cvmat.
                return sum([cvmat[i, 0] for i in range(cvmat.rows)])
            elif cvmat.cols > 1:
                return sum([cvmat[0, i] for i in range(cvmat.cols)])

    def grayscale_to_color(self, image):
        color = cv.CreateMat(image.height, image.width, cv.CV_8UC3)
        cv.CvtColor(image, color, cv.CV_GRAY2RGB)
        return color
