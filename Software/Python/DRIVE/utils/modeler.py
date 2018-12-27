# keras imports
from keras.models import Model
from keras import backend as K
from keras.preprocessing import image
from keras.layers import Dense, GlobalAveragePooling2D
from keras.applications.inception_v3 import InceptionV3
from keras.preprocessing.image import ImageDataGenerator
from keras.callbacks import ModelCheckpoint, TensorBoard
import os 

class Modeler(object):
    def __init__(self, model_type):
        self.model_type = model_type
    
    # big bad list of tensorflow/keras models
    def createModel(self):
        path = os.path.dirname(os.path.realpath(__file__))

        if self.model_type == "cup" or self.model_type == "hand":

            # just a fine tuned InceptionV3 net, weights calculated by the ML module
            # keras documentation if you need help: https://keras.io/
            base_model = InceptionV3(weights='imagenet', include_top=False)
            x = base_model.output
            x = GlobalAveragePooling2D()(x)
            x = Dense(128, activation='relu')(x)
            x = Dense(64, activation='relu')(x)
            x = Dense(32, activation='relu')(x)
            predictions = Dense(2, activation='softmax')(x)
            model = Model(inputs=base_model.input, outputs=predictions)
            if self.model_type == "cup":
                model.load_weights(path + '/Models/cup.hdf5')

            elif self.model_type == "hand":
                model.load_weights(path + '/Models/hand.hdf5')

            return model