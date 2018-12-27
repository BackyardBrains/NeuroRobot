import cv2
import glob
import matplotlib.pyplot as plt
import numpy.random as random
import os

print("Welcome to the Ilya-brand image renamer and resizer. This program renames all images in the desired directory to randomNumber_label.jpg, and resizes them to squares of size x.")
x = input("Enter x, desired square size: \n")
path = input("Enter path to images:  \n")
destination = input("Enter destination for squares: \n")
label = input("Enter label for squares:  \n")

filenames = glob.glob(str(path) + "*.JPG")
if len(filenames) == 0:
    filenames = glob.glob(str(path) + "*.jpg")

names = random.choice(range(999999), len(filenames), replace=False)

for i, img in enumerate(filenames):
    n_ = cv2.resize(cv2.imread(img), (int(x), int(x)), interpolation=cv2.INTER_NEAREST)
    cv2.imwrite(str(destination) + str(names[i]) + "_" + str(label) + ".jpg", n_)
    os.remove(img)
