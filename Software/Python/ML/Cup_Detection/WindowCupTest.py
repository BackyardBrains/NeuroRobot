import glob
import os.path
import queue
import random
import string
import time

import cv2
import matplotlib.pyplot as plt
import numpy as np
import requests
import scipy
from drawnow import drawnow
from keras import backend as K
from keras.applications.inception_v3 import InceptionV3
from keras.callbacks import ModelCheckpoint, TensorBoard
from keras.layers import Dense, GlobalAveragePooling2D
from keras.models import Model
from keras.preprocessing import image
from keras.preprocessing.image import ImageDataGenerator

# load keras model to run predictions
def createModel(base_model):
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dense(128, activation='relu')(x)
    x = Dense(64, activation='relu')(x)
    x = Dense(32, activation='relu')(x)
    predictions = Dense(2, activation='softmax')(x)
    model = Model(inputs=base_model.input, outputs=predictions)
    
    return model

# split image into 50% overlapping windows
# x number of windows horizontally, y vertically
# returned as representitive 2D array
def imageSplitter(img, x, y):
    split = np.empty((y, x), dtype=np.ndarray)
    xStep, yStep = len(img[0])//(x+1), len(img)//(y+1)
    for i in range(x):
        for j in range(y):
            snip = img[j*yStep:(j+2)*yStep,i*xStep:(i+2)*xStep]
            snip = cv2.resize(snip, (150,150), interpolation=cv2.INTER_NEAREST)
            snip  = cv2.cvtColor(snip, cv2.COLOR_BGR2RGB)*(1./255)
            split[j, i] = snip

    return split

# plot probability circles
def make_fig():
    plt.ylim(0,0.9)
    plt.xlim(0,1.2)
    p0,p1,p2 = [np.mean(list(i.queue)) for i in qArray]

    plt.scatter(0.3,0.45, s=int(2048*p0), c=[p0, 0.5, p0])
    plt.scatter(0.6,0.45, s=int(2048*p1), c=[p1, 0.5, p1])
    plt.scatter(0.9,0.45, s=int(2048*p2), c=[p2, 0.5, p2])




def initializeQueues(numQ, sizeQ):
    q = [queue.Queue() for i in range(numQ)]
    # initialize queues to sizeQ zeroes
    for i in range(sizeQ):
        for j in range(numQ):
            q[j].put(0)
    return q

# append entries of arr onto all queues
def updateQueues(qArray, arr):
    for i, q in enumerate(qArray):
        q.put(arr[i])
        q.get()


plt.ion()  # enable interactivity
fig = plt.figure()  # make a figure

qArray = initializeQueues(3, 5)

cap = cv2.VideoCapture(0)

base_model = InceptionV3(weights='imagenet', include_top=False)
model = createModel(base_model)
model.load_weights('Models/cup06-27-18:11:38.hdf5')
record = True
count = 0

while record:
    for i in range(3):
        cap.grab()
    ret, frame = cap.read()
    
    # process image for input into model
    ims = imageSplitter(frame, 3, 1)
    ims = [ims[0,0], ims[0,1], ims[0,2]]

    # input into model
    probabilities = model.predict(np.array(ims))
    probabilities = [i[0] for i in probabilities]
    # update rolling averages
    updateQueues(qArray, probabilities)
    p0,p1,p2 = np.round(probabilities, 2)

    print("------------")
    print(p0, "|", p1, "|", p2)
    print("------------")

    if count%2 == 0:
        drawnow(make_fig)
    count += 1


    if ret:
        cv2.imshow('frame', frame)
    else:
        break

    if cv2.waitKey(1) & 0xFF == ord('q'):
        plt.close()
        cap.release()
        cv2.destroyAllWindows()
        record = False
        break
        

cap.release()
cv2.destroyAllWindows()