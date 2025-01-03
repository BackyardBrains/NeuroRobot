const StateLength = 20;
const COLOR_CHANNELS = 3;
const cameraWidth = 320;
const cameraHeight = 240;

let neuronSize = 1;
const visualInputLen = 22;
const normalNeuronStartIdx = 12;
const tempAiBoundingBox = new Float32Array(6);

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

// var ptrPreprocessStateBuffer;
// var sabPreprocessStateBuffer;
// var ptrPreprocessCameraBuffer;
// var sabPreprocessCameraBuffer;
// var preprocessCameraBuffer;

// var ptrPreprocessNeuronContacts;
// var sabPreprocessNeuronContacts;

// var ptrPreprocessVisPrefs;
// var sabPreprocessVisPrefs;
// var ptrPreprocessVisPrefVals;
// var sabPreprocessVisPrefVals;


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
// self.importScripts('https://cdn.jsdelivr.net/npm/@tensorflow/tfjs@4.22.0/dist/tf.min.js');
// self.importScripts('https://cdn.jsdelivr.net/npm/@tensorflow/tfjs@latest/dist/tf.min.js');
/*
self.importScripts('tfjs-core.js');
self.importScripts('tfjs-backend-cpu.js');
self.importScripts('tfjs-tflite@0.0.1-alpha.10.js')
*/
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
// self.importScripts('https://cdn.jsdelivr.net/npm/@tensorflow/tfjs-core');
// self.importScripts('https://cdn.jsdelivr.net/npm/@tensorflow/tfjs-backend-cpu');
// self.importScripts('https://cdn.jsdelivr.net/npm/@tensorflow/tfjs-tflite@0.0.1-alpha.10')

// self.importScripts('https://cdn.jsdelivr.net/npm/@tensorflow/tfjs-tflite@latest/dist/tf-tflite.min.js');

// cocoSsd.load().then(model => {
//     // detect objects in the image.
//     console.log('COCOS LOADED0: ');
//     tfliteModel = model;
// });


self.onmessage = async function(eventFromMain){
    switch (eventFromMain.data.message){
        case "MOCK":
            console.log("MOCKED0");
            // const response = await fetch("https://storage.googleapis.com/tfjs-models/savedmodel/ssdlite_mobilenet_v2/model.json",   {
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
            sabStateBuffer = eventFromMain.data.sabStateBuffer;
            sabAiBoundingBox = eventFromMain.data.sabAiBoundingBox;
            console.log("sabStateBufferzz");
            console.log(sabStateBuffer);
            // sabCameraPreprocessBuffer = eventFromMain.data.sabCameraPreprocessBuffer;
            sabVisualInputBuf = eventFromMain.data.sabVisualInputBuf;
            sabVisPrefs = eventFromMain.data.sabVisPrefs;
            sabVisPrefVals = eventFromMain.data.sabVisPrefVals;
            sabNeuronContacts = eventFromMain.data.sabNeuronContacts;
            sabAiPreprocessCameraBuffer = eventFromMain.data.sabAiPreprocessCameraBuffer;
            sabAiRgbCameraBuffer = new Uint8Array(cameraWidth * cameraHeight / 4 * 3);
            sabPreprocessObjectDetection = new Float32Array(new SharedArrayBuffer( 7 * Float32Array.BYTES_PER_ELEMENT ));
            // console.log("tf", tf);
            // console.log("tf", tflite);
            
            neuronSize = eventFromMain.data.neuronSize;
            tempAiBoundingBox.fill(0);
            // console.log("INITIALIZE ", sabStateBuffer);
            // Load the model
            if (tfliteModel === undefined) {
                // tflite.setWasmPath('https://cdn.jsdelivr.net/npm/@tensorflow/tfjs-tflite@0.0.1-alpha.10/wasm/')                
                /*
                tflite.setWasmPath('tflitewasm/')                
                tflite.loadTFLiteModel('ssd_mobilenet.tflite').then(model => {
                // tf.loadLayersModel('https://firebasestorage.googleapis.com/v0/b/neurorobot-byb.firebasestorage.app/o/ssd_mobilenet.tflite?alt=media&token=0bd41eed-2bb3-4e7a-890d-7a3bbaa9307b').then(model => {
                // tf.loadTFLiteModel('https://storage.googleapis.com/tfweb/models/cartoongan_fp16.tflite').then(model => {
                // tflite.loadTFLiteModel('https://firebasestorage.googleapis.com/v0/b/neurorobot-byb.firebasestorage.app/o/ssd_mobilenet.tflite?alt=media&token=0bd41eed-2bb3-4e7a-890d-7a3bbaa9307b').then(model => {
                // tf.loadLayersModel('https://tfhub.dev/tensorflow/lite-model/mobilenet_v2_1.0_224/1/metadata/1').then(model => {
                    tfliteModel = model;
                    postMessage({
                        "message": "INITIALIZED",
                        "sabPreprocessObjectDetection": sabPreprocessObjectDetection,
                    });
                }).catch((err) => {
                    console.log("err");
                    console.log(err);
                });    
                */

            } else {
                /*
                const input = sabAiPreprocessCameraBuffer.slice(0, sabStateBuffer[STATE.AIPROCESS_IMAGE_LENGTH]);
                let outputTensor = tfliteModel.predict(input);
                */
                // const inputData = sabAiPreprocessCameraBuffer.slice(0, sabStateBuffer[STATE.AIPROCESS_IMAGE_LENGTH]);
                // const rgbaTens3d = tf.tensor3d(inputData, [320, 320, 4])
                // const rgbTens3d= tf.slice3d(rgbaTens3d, [0, 0, 0], [-1, -1, 3]) // strip alpha channel
                // const tensor = tf.cast(rgbTens3d, 'int32');

                // tfliteModel.detect(tensor).then(predictions => {
                //   console.log('Predictions: ', predictions);
                // });
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
                // Atomics.store(sabStateBuffer, STATE.AIPROCESS_IMAGE_PROCESSING, 1);

                // sabStateBuffer[7] = -10000; // passing pointer should be from the WASM allocation
                
                // sabPreprocessStateBuffer.set(sabStateBuffer);
                // sabPreprocessVisPrefs.set(sabVisPrefs);
                // sabPreprocessVisPrefVals.set(sabVisPrefVals);
                // preprocessCameraBuffer.set(sabPreprocessCameraBuffer);
                // console.log("RUNNING PREPROCESS STATE : ", sabStateBuffer[STATE.PREPROCESS_IMAGE_LENGTH]);

                // only call wasm function - pass pointer esp vis_pref_vals
                // Module.ccall(
                //     'findColorInImage',
                //     'number',
                //     ['number', 'number', 'number'],
                //     [ ptrPreprocessCameraBuffer, sabStateBuffer[STATE.PREPROCESS_IMAGE_LENGTH], ptrPreprocessCameraBuffer]
                // );
                // output : change vis_pref_vals pointer so it can be processed by neuronSimulator.
                // console.log("RUNNING PREPROCESS 23: ", sabPreprocessCameraBuffer, ptrPreprocessCameraBuffer);
                // console.log("RUNNING PREPROCESS 22: ");
                /*
                const inputData = sabAiPreprocessCameraBuffer.slice(0, sabStateBuffer[STATE.AIPROCESS_IMAGE_LENGTH]);
                let ctr = 0;
                for (let i = 0; i < inputData.length; i += 4) {
                    // rgbData.push(pixelData[i], pixelData[i + 1], pixelData[i + 2]);
                    sabAiRgbCameraBuffer[ctr] = inputData[i];
                    sabAiRgbCameraBuffer[ctr + 1] = inputData[i + 1];
                    sabAiRgbCameraBuffer[ctr + 2] = inputData[i + 2];
                    ctr += 3;
                }
                console.log("sabAiRgbCameraBuffer");
                console.log(sabAiRgbCameraBuffer);
                const rawTensor = tf.tensor4d(sabAiRgbCameraBuffer, [1, 320/2, 240/2, 3], 'int32');
                let pretensor = tf.image.resizeBilinear(rawTensor, [320, 320]);
                // const pretensor = tf.tensor4d(sabAiPreprocessCameraBuffer, [1, 320/2, 240/2, 3]);
                const tensor = tf.cast(pretensor, 'int32');
                // .toFloat()
                // .div(255)
                // tensor = tensor.expandDims(0);
                // const uint8Tensor = tf.cast(tensor, 'uint8');
                */

                /*
                const rgbaTens3d = tf.tensor3d(inputData, [320, 320, 4])
                const rgbTens3d= tf.slice3d(rgbaTens3d, [0, 0, 0], [-1, -1, 3]) // strip alpha channel
                // const resizedTensor = tf.image.resizeBilinear(rgbTens3d, [320, 320]);
                // console.log("tensor", resizedTensor);
                const tensor4 = tf.expandDims(rgbTens3d, 0);
                const tensor = tf.cast(tensor4, 'int32');
                // */                
                // tensor.data().then((resizedData)=> {
                //     console.log("tensor");
                //     console.log(resizedData);
                //     console.log(inputData);
                // });
                // Assuming your model has an input named 'input_image'
                const inputData = sabAiPreprocessCameraBuffer.slice(0, sabStateBuffer[STATE.AIPROCESS_IMAGE_LENGTH]);
                const rgbaTens3d = tf.tensor3d(inputData, [320, 320, 4])
                const rgbTens3d= tf.slice3d(rgbaTens3d, [0, 0, 0], [-1, -1, 3]) // strip alpha channel
                const tensor = tf.cast(rgbTens3d, 'int32');
                
                var prediction;
                const predictions = await tfliteModel.detect(tensor);
                if (predictions.length > 0) {
                    prediction = predictions[0];
                }

                // const inputs = {
                //     'normalized_input_image_tensor': tensor
                // };                
                // const prediction = tfliteModel.predict(inputs);
                rgbaTens3d.dispose();
                rgbTens3d.dispose();
                tensor.dispose();

                // console.log("prediction");
                // console.log(prediction);
                let idx = 0;
                let selClassIdx = -1;
                let selClassScore = -1;

                //   [
                //     {
                //         "bbox": [
                //             71.42716407775879,
                //             8.419408798217773,
                //             177.03619956970215,
                //             310.92164039611816
                //         ],
                //         "class": "person",
                //         "score": 0.9430490732192993
                //     }
                // ]                
                // const predictionKeys = Object.keys(prediction);
                // const boundingBoxKey = predictionKeys[0];
                // const objectDetectedKey = predictionKeys[1];
                // const scoreKey = predictionKeys[2];
                // const numberBoxesKey = predictionKeys[3];

                // const scoreValue = await prediction[scoreKey].data();
                sabPreprocessObjectDetection.fill(0);
                // if (scoreValue[0] > 0.6) {
                if (prediction !== undefined && prediction.score > 0.6) {
                    // const objectDetectedValue = await prediction[objectDetectedKey].data();
                    const objectDetectedValue = await prediction.class;
                    // selClassIdx = objectDetectedValue[0];
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
                        for (let neuronIdx = normalNeuronStartIdx; neuronIdx < neuronSize; neuronIdx++) {
                            const len = neuronIdx * visualInputLen;
                            const nodeLeftEyeSensor = 1;
                            const selectedVisualPreference = sabVisPrefs[nodeLeftEyeSensor * neuronSize + neuronIdx];
                            for (let optionIdx = 7; optionIdx < visualInputLen; optionIdx++) {
                                if (selectedVisualPreference == aiOptionIdx && optionIdx == aiOptionIdx) {
                                    sabVisualInputBuf[len + aiOptionIdx] = 50;
    
                                    // const boundingBoxValue = await prediction[boundingBoxKey].data();
                                    const boundingBoxValue = await prediction.bbox;
                                    // sabAiBoundingBox[0] = boundingBoxValue[0] * 240 / 2;
                                    // sabAiBoundingBox[1] = boundingBoxValue[1] * 320 / 2;
                                    // sabAiBoundingBox[2] = boundingBoxValue[2] * 240 / 2;
                                    // sabAiBoundingBox[3] = boundingBoxValue[3] * 320 / 2;
                                    sabAiBoundingBox[0] = boundingBoxValue[0] / 320 * 240 / 2;
                                    sabAiBoundingBox[1] = boundingBoxValue[1] / 320 * 320 / 2;
                                    sabAiBoundingBox[2] = boundingBoxValue[2] / 320 * 240 / 2;
                                    sabAiBoundingBox[3] = boundingBoxValue[3] / 320 * 320 / 2;
                                    sabAiBoundingBox[4] = sabAiBoundingBox[3] - sabAiBoundingBox[1]; // width
                                    sabAiBoundingBox[5] = sabAiBoundingBox[2] - sabAiBoundingBox[0]; // height
                                    sabAiBoundingBox[6] = aiOptionIdx; // index

                                    sabPreprocessObjectDetection[0] = aiOptionIdx;
                                    sabPreprocessObjectDetection[1] = prediction.score;
                                    sabPreprocessObjectDetection[2] = sabAiBoundingBox[0];
                                    sabPreprocessObjectDetection[3] = sabAiBoundingBox[1];
                                    sabPreprocessObjectDetection[4] = sabAiBoundingBox[2];
                                    sabPreprocessObjectDetection[5] = sabAiBoundingBox[3];
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



                // const nodeLeftEyeSensor = 1;
                // for (let idx = 0; idx < neuronSize; idx++) {
                //     const len = idx * visualInputLen;
                //     for (let aiOptionIdx = 3; aiOptionIdx < visualInputLen; aiOptionIdx++) {
                //         sabVisualInputBuf[len + aiOptionIdx] = sabPreprocessVisPrefVals[aiOptionIdx];
                //     }
                // }

                // Atomics.store(sabStateBuffer, STATE.AIPROCESS_IMAGE_PROCESSING, 0);
                // Atomics.store(sabStateBuffer, STATE.RECOGNIZE_IMAGE, 0);


                
                // prediction.data().then((d)=>{
                //     console.log(d);
                // })
                // detection_boxes = interpreter.get_tensor(output_details[0]['index'])                                                                                                              
                // detection_classes = interpreter.get_tensor(output_details[1]['index'])                                                                                                            
                // detection_scores = interpreter.get_tensor(output_details[2]['index'])                                                                                                             
                // num_boxes = interpreter.get_tensor(output_details[3]['index'])         

                
                // sabStateBuffer.set(sabPreprocessStateBuffer);
                // sabVisPrefs.set(sabPreprocessVisPrefs);
                // sabVisPrefVals.set(sabPreprocessVisPrefVals);
                // console.log("sabStateBuffer : ", sabStateBuffer[7]); // show 12323333
            }
        break;
    }
}