const StateLength = 20;
const COLOR_CHANNELS = 4;
const cameraWidth = 320;
const cameraHeight = 240;

let neuronSize = 1;

var sabStateBuffer;
var sabVisPrefs;
var sabVisPrefVals;
var sabNeuronContacts;

var ptrPreprocessStateBuffer;
var sabPreprocessStateBuffer;
var ptrPreprocessCameraBuffer;
var sabPreprocessCameraBuffer;
var preprocessCameraBuffer;

var ptrPreprocessNeuronContacts;
var sabPreprocessNeuronContacts;

var ptrPreprocessVisPrefs;
var sabPreprocessVisPrefs;
var ptrPreprocessVisPrefVals;
var sabPreprocessVisPrefVals;

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
};



self.importScripts("nativeopencv.js"); 
self.Module.onRuntimeInitialized = async _ => {
    console.log("WASM Preprocess Runtime Initialized", self.Module);
    // setTimeout(()=>{
        const matrixSize = neuronSize * neuronSize;
    
        ptrPreprocessStateBuffer = Module._malloc( StateLength * Module.HEAP32.BYTES_PER_ELEMENT );
        const startPreprocessStateBuffer = ptrPreprocessStateBuffer/Module.HEAP32.BYTES_PER_ELEMENT;
        sabPreprocessStateBuffer = Module.HEAP32.subarray(startPreprocessStateBuffer, startPreprocessStateBuffer + StateLength);
    
        const bufferLen = cameraWidth * cameraHeight * COLOR_CHANNELS;
        ptrPreprocessCameraBuffer = Module._malloc( bufferLen * Module.HEAPU8.BYTES_PER_ELEMENT );
        const startPreprocessCameraBuffer = ptrPreprocessCameraBuffer/Module.HEAPU8.BYTES_PER_ELEMENT;
        preprocessCameraBuffer = Module.HEAPU8.subarray(startPreprocessCameraBuffer, startPreprocessCameraBuffer + bufferLen);
        sabPreprocessCameraBuffer = new Uint8Array( new SharedArrayBuffer(bufferLen * Module.HEAPU8.BYTES_PER_ELEMENT) );
    
        
        ptrPreprocessNeuronContacts = Module._malloc( matrixSize * Module.HEAPF64.BYTES_PER_ELEMENT);
        const startPreprocessNeuronContacts = ptrPreprocessNeuronContacts/Module.HEAPF64.BYTES_PER_ELEMENT;
        sabPreprocessNeuronContacts = Module.HEAPF64.subarray( startPreprocessNeuronContacts, (startPreprocessNeuronContacts + matrixSize ));

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
            sabNeuronContacts = eventFromMain.data.sabNeuronContacts;
            
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

            while (Atomics.wait(sabStateBuffer, STATE.PREPROCESS_IMAGE, 0) === "ok"){
                // sabStateBuffer[7] = -10000; // passing pointer should be from the WASM allocation
                
                sabPreprocessStateBuffer.set(sabStateBuffer);
                sabPreprocessVisPrefs.set(sabVisPrefs);
                sabPreprocessVisPrefVals.set(sabVisPrefVals);
                preprocessCameraBuffer.set(sabPreprocessCameraBuffer);
                // console.log("RUNNING PREPROCESS STATE : ", sabStateBuffer[STATE.PREPROCESS_IMAGE_LENGTH]);

                // only call wasm function - pass pointer esp vis_pref_vals
                Module.ccall(
                    'findColorInImage',
                    'number',
                    ['number', 'number', 'number'],
                    [ ptrPreprocessCameraBuffer, sabStateBuffer[STATE.PREPROCESS_IMAGE_LENGTH], ptrPreprocessCameraBuffer]
                );
                // output : change vis_pref_vals pointer so it can be processed by neuronSimulator.
                // console.log("RUNNING PREPROCESS 23: ", sabPreprocessCameraBuffer, ptrPreprocessCameraBuffer);
                // console.log("RUNNING PREPROCESS 22: ", JSON.stringify(sabVisPrefVals));
                sabStateBuffer.set(sabPreprocessStateBuffer);
                sabVisPrefs.set(sabPreprocessVisPrefs);
                sabVisPrefVals.set(sabPreprocessVisPrefVals);
                sabStateBuffer[STATE.PREPROCESS_IMAGE_PROCESSING] = 0;
                Atomics.store(sabStateBuffer, STATE.PREPROCESS_IMAGE, 0);
                // console.log("sabStateBuffer : ", sabStateBuffer[7]); // show 12323333
            }
        break;

    }
}