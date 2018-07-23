import cv2
import numpy as np


class Detector(object):
    def __init__(self, model_type, color=None):
        self.model_type = model_type
        if model_type != "color":
            from .modeler import Modeler
            self.model = Modeler(model_type).createModel()
            
        else:
            # allowable deviation from desired colour
            self.h_bound = 15
            self.s_bound = 75
            self.v_bound = 75

            # note: in openCV HSV = (0-180, 0-255, 0-255)
            # instead of (0-360, 0-100, 0-100)
            if color == "red":
                self.color = (0,128,128)
            elif color == "orange":
                self.color = (15,128,128)
            elif color == "yellow":
                self.color = (30,128,128)
            elif color == "green":
                self.color = (60,128,128)
            elif color == "cyan":
                self.color = (90,128,128)
            elif color == "blue":
                self.color = (120,128,128)
            elif color == "purple":
                self.color = (145,128,128)
            elif color == "pink":
                self.color = (160,128,128)
            elif color == "light":
                self.color = (90,128,255)
                self.h_bound = 90
                self.s_bound = 128
                self.v_bound = 40

            else:
                self.color = color
            

    def imageSplitter(self, img, x, y):
        split = np.empty((y, x), dtype=np.ndarray)
        xStep, yStep = len(img[0])//(x+1), len(img)//(y+1)
        for i in range(x):
            for j in range(y):
                # cut image into 50% overlap snippets
                snip = img[j*yStep:(j+2)*yStep, i*xStep:(i+2)*xStep]
                # resize snippet to 150 by 150 square
                snip = cv2.resize(snip, (150, 150),
                                  interpolation=cv2.INTER_NEAREST)
                # convert to RGB and normalize to [0,1]
                snip = cv2.cvtColor(snip, cv2.COLOR_BGR2RGB)*(1./255)
                split[j, i] = snip

        return split

    def predict(self, frame):
        if self.model_type == "color":
            return self.predict_color(frame)
        else:
            return self.predict_item(frame)

    def predict_item(self, frame):
        # split image into left, center, right
        ims = self.imageSplitter(frame, 3, 1)
        ims = [ims[0, 0], ims[0, 1], ims[0, 2]]

        # input into model
        probabilities = self.model.predict(np.array(ims))
        probabilities = [i[0] for i in probabilities]

        # round probabilities to 3 decimal places
        p0, p1, p2 = np.round(probabilities, 3)
        return p0, p1, p2

    def predict_color(self, frame):
        # convert the frame to HSV for more logical thresholding
        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)

        # set thresholds and zero everything outside them
        min_h, max_h = max(self.color[0] - self.h_bound, 0), min(self.color[0] + self.h_bound, 180)
        min_s, max_s = max(self.color[1] - self.s_bound, 0), min(self.color[1] + self.s_bound, 255)
        min_v, max_v = max(self.color[2] - self.v_bound, 0), min(self.color[2] + self.v_bound, 255)

        thresh = cv2.inRange(frame, (min_h, min_s, min_v),(max_h, max_s, max_v))
        #improve red tracking by letting it wrap around
        if self.color[0] - self.h_bound < 0:
            min_h = (self.color[0] - self.h_bound) % 180
            thresh = thresh | cv2.inRange(frame, (min_h, min_s, min_v),(180, max_s, max_v))

        # find contours in thresholded image
        _, contours, _ = cv2.findContours(
            thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

        if len(contours) != 0:  # if contour is found

            # take contour of maximum area and fit ellipse
            cnt = max(contours, key=cv2.contourArea)
            if len(cnt) >= 5:
                ellipse = cv2.fitEllipse(cnt)
                ellipse_x = int(ellipse[0][0])
                area = cv2.contourArea(cnt)

                if ellipse_x < 360: # in left third of screen
                    return 0, 0, area

                elif ellipse_x > 720: # right third
                    return area, 0, 0

                else: # middle
                    return 0, area, 0
            else:
                return 0,0,0
        else:
            return 0,0,0
