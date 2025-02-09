const StateLength = 20;
const COLOR_CHANNELS = 3;
const cameraWidth = 320;
const cameraHeight = 240;
const nodeLeftEyeSensor = 1;

let neuronSize = 1;
const visualInputLen = 22;
const normalNeuronStartIdx = 12;
const tempAiBoundingBox = new Float32Array(6);
let prevPrediction;

var mapAreaSize;
var neuronKeys;
var sabStateBuffer;
var sabAiBoundingBox;
var sabAiPreprocessCameraBuffer;
var sabAiRgbCameraBuffer;
var sabVisPrefs;
var sabVisPrefVals;
var sabNeuronContacts;
let tfliteModel;
var sabPreprocessObjectDetection;
var sabVisualInputBuf;

const url = "http://192.168.4.1:81/stream";

const STATE = {
    "WEB_SOCKET":0,
    "PREPROCESS_IMAGE":1,
    "PREPROCESS_IMAGE_PROCESSING":2,
    "PREPROCESS_IMAGE_LENGTH":3,
    "COMMAND_MOTORS":4,
    "COMMAND_MOTORS_LENGTH":5,
    "CAMERA_CONTENT_LENGTH":6,
    "CAMERA_CONTENT_COMPLETE":7,
    "CAMERA_CONTENT_STOP":8,
    "RECOGNIZE_IMAGE":9,
    "RECOGNITION_IMAGE_PROCESSING":10,
    "RECOGNITION_IMAGE_LENGTH":11,
    "BATTERY_STATUS":12,
    "DISTANCE_STATUS":13, 
    "AIPROCESS_IMAGE_PROCESSING":14,
    "AIPROCESS_IMAGE_LENGTH":15,
};

let uiAiLabels = [
"Blue", // 1
"Blue (side)",
"Green",
"Green (side)",
"Red",
"Red (side)",
"Movement", // 7
"person",
"backpack",
"bottle",
"cup",
"bowl",
"banana",
"apple",
"orange",
"chair",
"couch",
"potted plant",
"laptop",
"cell phone",
"book",
"vase",
];

var aiLabels = ["person","bicycle","car","motorcycle","airplane","bus","train","truck","boat","traffic light","fire hydrant","???","stop sign","parking meter","bench","bird","cat","dog","horse","sheep","cow","elephant","bear","zebra","giraffe","???","backpack","umbrella","???","???","handbag","tie","suitcase","frisbee","skis","snowboard","sports ball","kite","baseball bat","baseball glove","skateboard","surfboard","tennis racket","bottle","???","wine glass","cup","fork","knife","spoon","bowl","banana","apple","sandwich","orange","broccoli","carrot","hot dog","pizza","donut","cake","chair","couch","potted plant","bed","???","dining table","???","???","toilet","???","tv","laptop","mouse","remote","keyboard","cell phone","microwave","oven","toaster","sink","refrigerator","???","book","clock","vase","scissors","teddy bear","hair drier","toothbrush"];
self.importScripts('runtime.js');
self.importScripts('tfjs.js');
self.importScripts('coco-ssd.js');
try {
    fetch("model.json",  {
        headers: {
        "Cache-Control": "max-age=172800"
      }
    }).then((response)=>{
        console.log("response");
        console.log(response);

    }).catch((err)=>{
        console.log("err: ", err);
    });
} catch(err) {
    console.log("err: ", err);
}

self.onmessage = async function(eventFromMain){
    switch (eventFromMain.data.message){
        case "MOCK":
            console.log("MOCKED0");
            const response = await fetch("model.json",   {
                headers: {
                    "Cache-Control": "max-age=172800"
                }
            }).then((response)=>{
                return response;
            }).catch((err)=>{
                console.log("err: ", err);
            });
        
            await cocoSsd.load().then(model => {
                // detect objects in the image.
                console.log('COCOS LOADED2: ');
                tfliteModel = model;
                postMessage({
                    "message": "MOCKED",
                    "sabPreprocessObjectDetection": sabPreprocessObjectDetection,
                });
            });
            console.log("MOCKED1");
        break;
        case "INITIALIZE":
            mapAreaSize = eventFromMain.data.mapAreaSize;
            neuronKeys = eventFromMain.data.neuronKeys;
            // console.log("mapAreaSize: ", mapAreaSize, neuronKeys, nodeLeftEyeSensor);
            sabStateBuffer = eventFromMain.data.sabStateBuffer;
            sabAiBoundingBox = eventFromMain.data.sabAiBoundingBox;
            // console.log("sabStateBufferzz");
            // console.log(sabStateBuffer);
            sabVisualInputBuf = eventFromMain.data.sabVisualInputBuf;
            sabVisPrefs = eventFromMain.data.sabVisPrefs;
            sabVisPrefVals = eventFromMain.data.sabVisPrefVals;
            sabNeuronContacts = eventFromMain.data.sabNeuronContacts;
            sabAiPreprocessCameraBuffer = eventFromMain.data.sabAiPreprocessCameraBuffer;
            sabAiRgbCameraBuffer = new Uint8Array(cameraWidth * cameraHeight / 4 * 3);
            sabPreprocessObjectDetection = new Float32Array(new SharedArrayBuffer( 7 * Float32Array.BYTES_PER_ELEMENT ));
            
            neuronSize = eventFromMain.data.neuronSize;
            tempAiBoundingBox.fill(0);
            // Load the model
            if (tfliteModel === undefined) {

            } else {
                postMessage({
                    "message": "INITIALIZED",
                    "sabPreprocessObjectDetection": sabPreprocessObjectDetection,
                });

            }

        break;
        case "START_RECOGNITION":
            // wake thread
            console.log("START_RECOGNITIONzzz");
            
            while (Atomics.wait(sabStateBuffer, STATE.RECOGNIZE_IMAGE, 0) === "ok"){
                // Assuming your model has an input named 'input_image'
                const inputData = sabAiPreprocessCameraBuffer.subarray(0, sabStateBuffer[STATE.AIPROCESS_IMAGE_LENGTH]);
                const rgbaTens3d = tf.tensor3d(inputData, [320, 320, 4])
                const rgbTens3d= tf.slice3d(rgbaTens3d, [0, 0, 0], [-1, -1, 3]) // strip alpha channel
                const tensor = tf.cast(rgbTens3d, 'int32');
                
                var prediction;
                const predictions = await tfliteModel.detect(tensor);
                if (predictions.length > 0) {
                    prediction = predictions[0];
                }
                if (prediction !== undefined) {
                    // console.log("PREDICTING RECOGNITION", prediction.score);
                    if (prevPrediction !== undefined && prediction.score === prevPrediction.score) {
                        // console.log("PREV PREDICTION RESET");
                        sabAiPreprocessCameraBuffer.fill(0);
                        sabAiBoundingBox[0] = -50;
                        sabAiBoundingBox[1] = -50;
                        sabAiBoundingBox[2] = -50;
                        sabAiBoundingBox[3] = -50;
                        sabAiBoundingBox[4] = 0; // width
                        sabAiBoundingBox[5] = 0; // height
                        sabAiBoundingBox[6] = -1; // index
                        for (let neuronIdx = normalNeuronStartIdx; neuronIdx < neuronSize; neuronIdx++) {
                            const len = neuronIdx * visualInputLen;
                            for (let optionIdx = 7; optionIdx < visualInputLen; optionIdx++) {
                                sabVisualInputBuf[len + optionIdx] = 0;
                            }
                        }
                        sabPreprocessObjectDetection.fill(0);
                        prevPrediction = prediction;
                        rgbaTens3d.dispose();
                        rgbTens3d.dispose();
                        tensor.dispose();
        
                        sabStateBuffer[STATE.AIPROCESS_IMAGE_PROCESSING] = 0;
                        Atomics.store(sabStateBuffer, STATE.RECOGNIZE_IMAGE, 0);
                        continue;
                    }
                }

                prevPrediction = prediction;


                rgbaTens3d.dispose();
                rgbTens3d.dispose();
                tensor.dispose();

                let idx = 0;
                let selClassIdx = -1;
                let selClassScore = -1;

                sabPreprocessObjectDetection.fill(0);
                if (prediction !== undefined && prediction.score > 0.6) {
                    const objectDetectedValue = await prediction.class;
                    selClassIdx = aiLabels.indexOf(objectDetectedValue);
                    let tfAiModelsString = aiLabels[selClassIdx];
                    const aiOptionIdx = uiAiLabels.indexOf(tfAiModelsString);
                    if (aiOptionIdx < 0) {
                        sabAiBoundingBox[0] = -50;
                        sabAiBoundingBox[1] = -50;
                        sabAiBoundingBox[2] = -50;
                        sabAiBoundingBox[3] = -50;
                        sabAiBoundingBox[4] = 0; // width
                        sabAiBoundingBox[5] = 0; // height
                        sabAiBoundingBox[6] = -1; // index
                        for (let neuronIdx = normalNeuronStartIdx; neuronIdx < neuronSize; neuronIdx++) {
                            const len = neuronIdx * visualInputLen;
                            for (let optionIdx = 7; optionIdx < visualInputLen; optionIdx++) {
                                sabVisualInputBuf[len + optionIdx] = 0;
                            }
                        }
                    } else {
                        const nodeLeftEyeSensorKey = neuronKeys[nodeLeftEyeSensor];
                        for (let neuronIdx = normalNeuronStartIdx; neuronIdx < neuronSize; neuronIdx++) {
                            const len = neuronIdx * visualInputLen;
                            const selectedVisualPreference = sabVisPrefs[nodeLeftEyeSensor * neuronSize + neuronIdx];
                            const currentSensorKey = neuronKeys[neuronIdx];
                            for (let optionIdx = 7; optionIdx < visualInputLen; optionIdx++) {
                                if (selectedVisualPreference == aiOptionIdx && optionIdx == aiOptionIdx) {

                                    const boundingBoxValue = await prediction.bbox;
                                    const tempBoundingBox = new Float32Array(7);
                                    
                                    tempBoundingBox[0] = boundingBoxValue[1] / 320 * 240 / 2; // y
                                    tempBoundingBox[1] = boundingBoxValue[0] / 320 * 320 / 2; // x
                                    tempBoundingBox[2] = boundingBoxValue[3] / 320 * 240 / 2; // height
                                    tempBoundingBox[3] = boundingBoxValue[2] / 320 * 320 / 2; // width
                                    tempBoundingBox[4] = tempBoundingBox[3]; // height
                                    tempBoundingBox[5] = tempBoundingBox[2]; // width
                                    tempBoundingBox[6] = aiOptionIdx; // index

                                    if (mapAreaSize[nodeLeftEyeSensorKey + "_" + currentSensorKey] !== undefined) {
                                        const center = getBoundingBoxCenter(tempBoundingBox[1], tempBoundingBox[0], tempBoundingBox[1] + tempBoundingBox[3], tempBoundingBox[0] + tempBoundingBox[2]);
                                        const location = {
                                            "center": center
                                        };
                                        const modes = (mapAreaSize[nodeLeftEyeSensorKey + "_" + currentSensorKey]).split("_@_");
                                        const flag = containImage(location, modes);
                                        if (flag) {
                                            sabAiBoundingBox[0] = tempBoundingBox[0]; // y
                                            sabAiBoundingBox[1] = tempBoundingBox[1]; // x
                                            sabAiBoundingBox[2] = tempBoundingBox[2]; // height
                                            sabAiBoundingBox[3] = tempBoundingBox[3]; // width
                                            sabAiBoundingBox[4] = tempBoundingBox[4]; // height
                                            sabAiBoundingBox[5] = tempBoundingBox[5]; // width
                                            sabAiBoundingBox[6] = tempBoundingBox[6]; // index
        
                                            sabPreprocessObjectDetection[0] = aiOptionIdx;
                                            sabPreprocessObjectDetection[1] = prediction.score;
                                            sabPreprocessObjectDetection[2] = sabAiBoundingBox[0];
                                            sabPreprocessObjectDetection[3] = sabAiBoundingBox[1];
                                            sabPreprocessObjectDetection[4] = sabAiBoundingBox[2];
                                            sabPreprocessObjectDetection[5] = sabAiBoundingBox[3];
                                            sabVisualInputBuf[len + aiOptionIdx] = 50;
                                        } else {
                                            sabVisualInputBuf[len + aiOptionIdx] = 0;
                                        }
                                    }
                                }else{
                                    sabVisualInputBuf[len + optionIdx] = 0;
                                }
                            }
                        }    
                    }
                } else {
                    sabAiBoundingBox[0] = -50;
                    sabAiBoundingBox[1] = -50;
                    sabAiBoundingBox[2] = -50;
                    sabAiBoundingBox[3] = -50;
                    sabAiBoundingBox[4] = 0; // width
                    sabAiBoundingBox[5] = 0; // height
                    sabAiBoundingBox[6] = -1; // index
                    for (let neuronIdx = normalNeuronStartIdx; neuronIdx < neuronSize; neuronIdx++) {
                        const len = neuronIdx * visualInputLen;
                        for (let optionIdx = 7; optionIdx < visualInputLen; optionIdx++) {
                            sabVisualInputBuf[len + optionIdx] = 0;
                        }
                    }
                }
                sabStateBuffer[STATE.AIPROCESS_IMAGE_PROCESSING] = 0;
                Atomics.store(sabStateBuffer, STATE.RECOGNIZE_IMAGE, 0);
            }
        break;
    }
}


function containImage(location, modes) {
    let xStart = parseInt(modes[1])/2;
    let xEnd = parseInt(modes[2])/2;
    if (modes[0] == "Left") {
      if (location.center.dx < xEnd && location.center.dx >= xStart) {
        return true;
      } else {
        return false;
      }
    } else if (modes[0] == "Right") {
      if (location.center.dx > xStart && location.center.dx <= xEnd) {
        return true;
      } else {
        return false;
      }
    } else if (modes[0] == "Any") {
      // any
      return true;
    } else if (modes[0] == "Custom") {
      // custom
      if (location.center.dx >= xStart && location.center.dx <= xEnd) {
        return true;
      } else {
        return false;
      }
    }
    return false;
  }


  function getBoundingBoxCenter(left, top, right, bottom) {
    // const left, top, right, bottom
    const width = right - left;
    const height = bottom - top;
    const centerX = left + (width / 2);
    const centerY = top + (height / 2);
  
    return { dx: centerX, dy: centerY };
  }