const StateLength = 20;
const COLOR_CHANNELS = 4;
const cameraWidth = 320;
const cameraHeight = 240;

let neuronSize = 1;

var sabStateBuffer;
var sabVisPrefs;
var sabVisPrefVals;

var ptrPreprocessStateBuffer;
var sabPreprocessStateBuffer;
var ptrPreprocessCameraBuffer;
var sabPreprocessCameraBuffer;

var ptrPreprocessVisPrefs;
var sabPreprocessVisPrefs;
var ptrPreprocessVisPrefVals;
var sabPreprocessVisPrefVals;

const url = "http://192.168.4.1:81/stream";

const STATE = {
    "WEB_SOCKET":0,
    "PREPROCESS_IMAGE":1,
    "PREPROCESS_IMAGE_LENGTH":2,
    "COMMAND_MOTORS":3,
    "COMMAND_MOTORS_LENGTH":4,
    "CAMERA_CONTENT_LENGTH":5,
    "CAMERA_CONTENT_COMPLETE":6,
};


self.importScripts("nativeopencv.js"); 
self.Module.onRuntimeInitialized = async _ => {
    console.log("WASM Runtime Initialized", self.Module);
    // setTimeout(()=>{
        const matrixSize = neuronSize * neuronSize;
    
        ptrPreprocessStateBuffer = Module._malloc( StateLength * Module.HEAP32.BYTES_PER_ELEMENT );
        const startPreprocessStateBuffer = ptrPreprocessStateBuffer/Module.HEAP32.BYTES_PER_ELEMENT;
        sabPreprocessStateBuffer = Module.HEAP32.subarray(startPreprocessStateBuffer, startPreprocessStateBuffer + StateLength);
    
        const bufferLen = cameraWidth * cameraHeight * COLOR_CHANNELS;
        ptrPreprocessCameraBuffer = Module._malloc( bufferLen * Module.HEAPU8.BYTES_PER_ELEMENT );
        const startPreprocessCameraBuffer = ptrPreprocessCameraBuffer/Module.HEAPU8.BYTES_PER_ELEMENT;
        sabPreprocessCameraBuffer = Module.HEAPU8.subarray(startPreprocessCameraBuffer, startPreprocessCameraBuffer + bufferLen);
    
    
        ptrPreprocessVisPrefs = Module._malloc( matrixSize * Module.HEAP16.BYTES_PER_ELEMENT);
        const startPreprocessVisPrefs = ptrPreprocessVisPrefs/Module.HEAP16.BYTES_PER_ELEMENT;
        sabPreprocessVisPrefs = Module.HEAP16.subarray( startPreprocessVisPrefs, (startPreprocessVisPrefs + matrixSize ));

        const prefCameraLength = 7 * 2;
        ptrPreprocessVisPrefVals = Module._malloc( prefCameraLength * Module.HEAPF64.BYTES_PER_ELEMENT);
        const startPreprocessVisPrefVals = ptrPreprocessVisPrefVals/Module.HEAPF64.BYTES_PER_ELEMENT;
        sabPreprocessVisPrefVals = Module.HEAPF64.subarray( startPreprocessVisPrefVals, (startPreprocessVisPrefVals + prefCameraLength ));
        
    
        postMessage({
            message:'INITIALIZED_WASM_PREPROCESS',
            sabPreprocessCameraBuffer:sabPreprocessCameraBuffer
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
            neuronSize = eventFromMain.data.neuronSize;
    
        break;
        case "START":
            // wake thread
            console.log("PREPROCESS START");
            // Pass pointer first
            Module.ccall(
                'passPreprocessPointers',
                'number',
                ['number', 'number', 'number', 'number'],
                [ ptrPreprocessStateBuffer, ptrPreprocessCameraBuffer, ptrPreprocessVisPrefs, ptrPreprocessVisPrefVals]
            );

            while (Atomics.wait(sabStateBuffer, STATE.PREPROCESS_IMAGE, 0) === "ok"){
                // sabStateBuffer[7] = -10000; // passing pointer should be from the WASM allocation
                sabPreprocessStateBuffer.set(sabStateBuffer);
                sabPreprocessVisPrefs.set(sabVisPrefs);
                sabPreprocessVisPrefVals.set(sabVisPrefVals);

                // only call wasm function - pass pointer esp vis_pref_vals
                Module.ccall(
                    'findColorInImage',
                    'number',
                    ['number', 'number', 'number'],
                    [ ptrPreprocessCameraBuffer, sabStateBuffer[STATE.PREPROCESS_IMAGE_LENGTH], ptrPreprocessCameraBuffer]
                );
                // output : change vis_pref_vals pointer so it can be processed by neuronSimulator.
                sabStateBuffer.set(sabPreprocessStateBuffer);
                sabVisPrefs.set(sabPreprocessVisPrefs);
                sabVisPrefVals.set(sabPreprocessVisPrefVals);

                Atomics.store(sabStateBuffer, STATE.PREPROCESS_IMAGE, 0);
                // console.log("sabStateBuffer : ", sabStateBuffer[7]);
            }
        break;

    }
}