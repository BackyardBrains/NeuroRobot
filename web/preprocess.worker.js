const StateLength = 70;
const COLOR_CHANNELS = 3;
const cameraWidth = 320;
const cameraHeight = 240;

let neuronSize = 0;
let normalNeuronStartIdx = 12;
let openCvOptions = 7;

var sabStateBuffer;
var sabVisPrefs;
var sabVisPrefVals;
var sabNeuronContacts;
var sabVisualInputBuf;

let visualInputLen = 22;
let visualInputLength;
var ptrPreprocessVisualInputBuf;
var sabPreprocessVisualInputBuf;

var ptrPreprocessStateBuffer;
var sabPreprocessStateBuffer;
var ptrPreprocessCameraBuffer;
var sabPreprocessCameraBuffer;
var preprocessCameraBuffer;

var ptrPreprocessNeuronContacts;
var sabPreprocessNeuronContacts;

var ptrPreprocessCentroid;
var sabPreprocessCentroid;

var ptrPreprocessVisPrefs;
var sabPreprocessVisPrefs;
var ptrPreprocessVisPrefVals;
var sabPreprocessVisPrefVals;

var sabPreprocessColorDetection;
var sabPreprocessObjectDetection;

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



self.importScripts("nativeopencv.js"); 
self.Module.onRuntimeInitialized = async _ => {
    console.log("WASM Preprocess Runtime Initialized", self.Module);
    // setTimeout(()=>{
        const matrixSize = neuronSize * neuronSize;
        ptrPreprocessStateBuffer = Module._malloc( StateLength * Module.HEAP32.BYTES_PER_ELEMENT );
        const startPreprocessStateBuffer = ptrPreprocessStateBuffer/Module.HEAP32.BYTES_PER_ELEMENT;
        sabPreprocessStateBuffer = Module.HEAP32.subarray(startPreprocessStateBuffer, startPreprocessStateBuffer + StateLength);
    
        const bufferLen = cameraWidth * cameraHeight * COLOR_CHANNELS ;
        ptrPreprocessCameraBuffer = Module._malloc( bufferLen * Module.HEAPU8.BYTES_PER_ELEMENT );
        const startPreprocessCameraBuffer = ptrPreprocessCameraBuffer/Module.HEAPU8.BYTES_PER_ELEMENT;
        preprocessCameraBuffer = Module.HEAPU8.subarray(startPreprocessCameraBuffer, startPreprocessCameraBuffer + bufferLen);
        sabPreprocessCameraBuffer = new Uint8Array( new SharedArrayBuffer(bufferLen * Module.HEAPU8.BYTES_PER_ELEMENT) );
    
        
        ptrPreprocessNeuronContacts = Module._malloc( matrixSize * Module.HEAPF64.BYTES_PER_ELEMENT);
        const startPreprocessNeuronContacts = ptrPreprocessNeuronContacts/Module.HEAPF64.BYTES_PER_ELEMENT;
        sabPreprocessNeuronContacts = Module.HEAPF64.subarray( startPreprocessNeuronContacts, (startPreprocessNeuronContacts + matrixSize ));
       
        const centroidLength = 3 * COLOR_CHANNELS;
        ptrPreprocessCentroid = Module._malloc( centroidLength * Module.HEAP16.BYTES_PER_ELEMENT);
        const startPreprocessCentroid = ptrPreprocessCentroid/Module.HEAP16.BYTES_PER_ELEMENT;
        sabPreprocessCentroid = Module.HEAP16.subarray( startPreprocessCentroid, (startPreprocessCentroid + centroidLength ));
        sabPreprocessCentroid.fill(0);

        ptrPreprocessVisPrefs = Module._malloc( matrixSize * Module.HEAP16.BYTES_PER_ELEMENT);
        const startPreprocessVisPrefs = ptrPreprocessVisPrefs/Module.HEAP16.BYTES_PER_ELEMENT;
        sabPreprocessVisPrefs = Module.HEAP16.subarray( startPreprocessVisPrefs, (startPreprocessVisPrefs + matrixSize ));

        const prefCameraLength = visualInputLen * 2;
        // const prefCameraLength = matrixSize;
        ptrPreprocessVisPrefVals = Module._malloc( prefCameraLength * Module.HEAPF64.BYTES_PER_ELEMENT);
        const startPreprocessVisPrefVals = ptrPreprocessVisPrefVals/Module.HEAPF64.BYTES_PER_ELEMENT;
        sabPreprocessVisPrefVals = Module.HEAPF64.subarray( startPreprocessVisPrefVals, (startPreprocessVisPrefVals + prefCameraLength ));

        visualInputLength = neuronSize * visualInputLen;
        ptrPreprocessVisualInputBuf = Module._malloc( visualInputLength * Module.HEAPF64.BYTES_PER_ELEMENT);
        const startPreprocessVisualInputBuf = ptrPreprocessVisPrefVals/Module.HEAPF64.BYTES_PER_ELEMENT;
        sabPreprocessVisualInputBuf = Module.HEAPF64.subarray( startPreprocessVisualInputBuf, (startPreprocessVisualInputBuf + visualInputLength ));
        
        
        
        postMessage({
            "message":'INITIALIZED_WASM_PREPROCESS',
            "sabPreprocessCameraBuffer":sabPreprocessCameraBuffer,
            "sabPreprocessColorDetection":sabPreprocessColorDetection,
        });
    // }, 1700);
}; 

self.onmessage = function(eventFromMain){
    switch (eventFromMain.data.message){
        case "INITIALIZE":
            sabStateBuffer = eventFromMain.data.sabStateBuffer;
            // sabCameraPreprocessBuffer = eventFromMain.data.sabCameraPreprocessBuffer;
            sabVisPrefs = eventFromMain.data.sabVisPrefs;
            sabVisPrefVals = eventFromMain.data.sabVisPrefVals;
            sabNeuronContacts = eventFromMain.data.sabNeuronContacts;
            sabVisualInputBuf = eventFromMain.data.sabVisualInputBuf;

            sabPreprocessColorDetection = new Int16Array(new SharedArrayBuffer( 3 * COLOR_CHANNELS * Int16Array.BYTES_PER_ELEMENT ));

            
            neuronSize = eventFromMain.data.neuronSize;
            // console.log("INITIALIZE ", sabStateBuffer);
    
        break;
        case "START_PREPROCESS":
            // wake thread
            console.log("PREPROCESS START", JSON.stringify(sabVisPrefVals) );
            // Pass pointer first
            Module.ccall(
                'passPreprocessPointers',
                'number',
                ['number', 'number', 'number', 'number'],
                [ ptrPreprocessStateBuffer, ptrPreprocessVisPrefVals, ptrPreprocessVisPrefs, ptrPreprocessNeuronContacts]
            );
            console.log("!@!sabPreprocessStateBuffer");
            console.log(sabPreprocessStateBuffer);
            while (Atomics.wait(sabStateBuffer, STATE.PREPROCESS_IMAGE, 0) === "ok"){
                try {
                    // console.log("RUNNING PREPROCESS STATE : ", sabStateBuffer[STATE.PREPROCESS_IMAGE_LENGTH]);
                    // sabStateBuffer[7] = -10000; // passing pointer should be from the WASM allocation
                    sabStateBuffer[STATE.PREPROCESS_IMAGE_PROCESSING] = 1;
                    if (sabPreprocessCentroid !== undefined) {
                        sabPreprocessCentroid.fill(0);
                    }
                    sabPreprocessStateBuffer.set(sabStateBuffer);
                    // sabPreprocessVisPrefs.set(sabVisPrefs);
                    // sabPreprocessVisPrefVals.set(sabVisPrefVals);
                    // sabPreprocessVisualInputBuf.set(sabVisualInputBuf);
                    preprocessCameraBuffer.set(sabPreprocessCameraBuffer);

                    // only call wasm function - pass pointer esp vis_pref_vals
                    const activeColorInt = Module.ccall(
                        'findColorInImage',
                        'number',
                        ['number', 'number', 'number'],
                        [ ptrPreprocessCameraBuffer, sabStateBuffer[STATE.PREPROCESS_IMAGE_LENGTH], ptrPreprocessCentroid]
                    );
                    const activeColorString = activeColorInt.toString(2);
                    // output : change vis_pref_vals pointer so it can be processed by neuronSimulator.
                    // sabPreprocessColorDetection[0] = parseInt(activeColorString.charAt[0]);
                    // sabPreprocessColorDetection[1] = parseInt(activeColorString.charAt[1]);
                    // sabPreprocessColorDetection[2] = parseInt(activeColorString.charAt[2]);
                    // sabPreprocessColorDetection[3] = parseInt(activeColorString.charAt[3]);
                    // let colorFlag = false;
                    for (let neuronIdx = normalNeuronStartIdx; neuronIdx < neuronSize; neuronIdx++) {
                        const len = neuronIdx * visualInputLen;
                        const nodeLeftEyeSensor = 1;
                        const selectedVisualPreference = sabVisPrefs[nodeLeftEyeSensor * neuronSize + neuronIdx];
                        if (selectedVisualPreference == 0) { // BLUE
                            sabPreprocessColorDetection[0] = sabPreprocessCentroid[0]  ;
                            sabPreprocessColorDetection[1] = sabPreprocessCentroid[1] *1.5 ;
                            sabPreprocessColorDetection[2] = sabPreprocessCentroid[2];
                            // if (sabPreprocessCentroid[2] > 68) {
                            //     colorFlag = true;
                            // }
                        } else
                        if (selectedVisualPreference == 2) { // GREEN
                            sabPreprocessColorDetection[3] = sabPreprocessCentroid[3];
                            sabPreprocessColorDetection[4] = sabPreprocessCentroid[4] *1.5 ;
                            sabPreprocessColorDetection[5] = sabPreprocessCentroid[5];
                            // if (sabPreprocessCentroid[5] > 68) {
                            //     colorFlag = true;
                            // }
                        } else
                        if (selectedVisualPreference == 4) { // RED
                            sabPreprocessColorDetection[6] = sabPreprocessCentroid[6] ;
                            sabPreprocessColorDetection[7] = sabPreprocessCentroid[7] *1.5 ;
                            sabPreprocessColorDetection[8] = sabPreprocessCentroid[8];
                            // if (sabPreprocessCentroid[8] > 68) {
                            //     colorFlag = true;
                            // }
                        }
                    }
                
                    // sabPreprocessColorDetection.set(sabPreprocessCentroid);
                    // console.log("sabPreprocessCentroid: ", sabPreprocessColorDetection);
                    let activeColorIdx = activeColorString.lastIndexOf(1);
                    activeColorIdx -=1;
                    if (activeColorIdx == -1 || activeColorIdx == -2) {
                        activeColorIdx= -200;
                    }
                    activeColorIdx *= 2;
                    // console.log("activeColorIdx", activeColorIdx);
                    // sabStateBuffer.set(sabPreprocessStateBuffer);
                    // sabVisPrefs.set(sabPreprocessVisPrefs);
                    // sabVisPrefVals.set(sabPreprocessVisPrefVals);
                    const nodeLeftEyeSensor = 1;
                    for (let idx = 0; idx < neuronSize; idx++) {
                        const selectedVisualPreference = sabVisPrefs[nodeLeftEyeSensor * neuronSize + idx];
                        const valueIdx = idx * visualInputLen + activeColorIdx;
                        const len = idx * visualInputLen;
                        sabVisualInputBuf[len] = sabPreprocessVisPrefVals[0];
                        sabVisualInputBuf[len+1] = sabPreprocessVisPrefVals[1];
                        sabVisualInputBuf[len+2] = sabPreprocessVisPrefVals[2];
                        // sabVisualInputBuf.fill(0, len, len + 4);
                        // if ( selectedVisualPreference == activeColorIdx) {
                        //     console.log("FOUND IDX: ", idx, valueIdx, selectedVisualPreference, sabPreprocessVisPrefVals[activeColorIdx]);
                        //     sabVisualInputBuf[valueIdx] = sabPreprocessVisPrefVals[activeColorIdx];
                        //     // for (let i = 0; i < openCvOptions; i++) {
                        //     //     const openCvIdx = neuronSize * visualInputLength + i;
                        //     //     sabVisualInputBuf[openCvIdx] = sabPreprocessVisualInputBuf[openCvIdx];
                        //     // }
                        // }
                    }
                    
                    // add the AI Value into visual prefs value
                    sabStateBuffer[STATE.PREPROCESS_IMAGE_PROCESSING] = 0;
                    // Atomics.store(sabStateBuffer, STATE.PREPROCESS_IMAGE_PROCESSING, 0);
                    Atomics.store(sabStateBuffer, STATE.PREPROCESS_IMAGE, 0);
                    // console.log("RESET state");
                    // console.log("sabStateBuffer : ", sabStateBuffer[7]); // show 12323333
                } catch (err) {
                    console.log("err image processing");
                    console.log(err);
                }
            }
        break;

    }
}