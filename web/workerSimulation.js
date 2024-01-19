const COLOR_CHANNELS = 4;
const CAMERA_BYTES_PER_ELEMENT = 1;
const MotorCommandsLength = 6 * 2;
const MotorMessageLength = 300;
const StateLength = 20;
const cameraWidth = 320;
const cameraHeight = 240;


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


// websocket
let ptrCameraDrawBuffer;
let ptrStateBuffer;
let sabCameraDrawBuffer;
let sabStateBuffer;
let isNotified = false;

let sabMotorMessageBuffer;

let statesDrawBuffer = new SharedArrayBuffer(StateLength * Int32Array.BYTES_PER_ELEMENT);
let statesDraw = new Int32Array(statesDrawBuffer);

let notifBuffer = new SharedArrayBuffer(1 * Int32Array.BYTES_PER_ELEMENT);
let notif = new Int32Array(notifBuffer);
notif[0]= -100;


let isConnectedAllocateBuffer = false;
let ptrCanvasBuffer;
let ptrNeuronCircle;
let ptrPos;
let ptrNps;


let sabNumNps;
let allocatedCanvasBuffer;
let selectedIdx=-1;
let neuronSize = 2;
let windowSize = 200 * 30;

// MOTOR
const totalCamera = 2;
const VisPrefsLength = 7;
let ptrVisPrefs;
let ptrVisPrefVals;
let ptrMotorCommands;
let sabVisPrefs;
let sabVisPrefVals;
let sabMotorCommands;

let ptrNeuronContacts;
let sabNeuronContacts;



let sabNumAPtr;
let sabNumBPtr;
let sabNumCPtr;
let sabNumDPtr;
let sabNumIPtr;
let sabNumWPtr;
let sabNumConnectomePtr;
// let startsabNumAPtr;
// let startsabNumBPtr;
// let startsabNumCPtr;
// let startsabNumDPtr;
// let startsabNumIPtr;
// let startsabNumWPtr;
// let startsabNumConnectomePtr;
// let sabA;
// let sabB;
// let sabC;
// let sabD;
// let sabI;
// let sabW;
// let sabConnectome;
// let sabNeuronCircle;
// let sabPos;
let sabCom;
let sabIsPlaying;
let sabConfig;



let sabNumA;
let sabNumB;
let sabNumC;
let sabNumD;
let sabNumI;
let sabNumW;
let sabNumConnectome;
let sabNumPos;
let sabNumNeuronCircle;
let abPrevNumNeuronCircle;

let sabNumCom;
let sabNumIsPlaying;
let sabNumConfig;

let simulationWorkerChannelPort;
let initializeChannelPort;


// let tempBuffer = new SharedArrayBuffer( bufSize * Float64Array.BYTES_PER_ELEMENT )
// let tempBufferNum = new Float64Array(tempBuffer);
let canvasBuffers = [];
let canvasBuffersNum = [];

const level = 1;
const envelopeSize = 200;
const bufferSize = 200 * 30;
let isPlaying = 1;


var vm = self;
var tempOnMessage = self.onmessage;
self.onmessage = async function( eventFromMain ) {
    console.log("eventFromMain.data.message");
    console.log(eventFromMain.data.message);
    if (eventFromMain.data.message === 'INITIALIZE_WORKER') {
        console.log("Initialize Worker branch")
        neuronSize = eventFromMain.data.neuronSize;
        // sabA = eventFromMain.data.sabA;
        // sabB = eventFromMain.data.sabB;
        // sabC = eventFromMain.data.sabC;
        // sabD = eventFromMain.data.sabD;
        // sabI = eventFromMain.data.sabI;
        // sabW = eventFromMain.data.sabW;
        // sabPos = eventFromMain.data.sabPos;
        // sabConnectome = eventFromMain.data.sabConnectome;
        // sabNeuronCircle = eventFromMain.data.sabNeuronCircle;
        
        // sabCanvas = eventFromMain.data.sabCanvas;
        // sabCom = eventFromMain.data.sabCom;
        // sabConfig = eventFromMain.data.sabConfig;
        // sabIsPlaying = eventFromMain.data.sabIsPlaying;

        // simulationWorkerChannelPort = eventFromMain.data.simulationWorkerChannelPort;
        // initializeChannelPort = eventFromMain.data.initializeChannelPort;
        // abPrevNumNeuronCircle = new Int16Array(neuronSize);
        
        // sabNumA = new Float64Array(sabA);
        // sabNumB = new Float64Array(sabB);
        // sabNumC = new Int16Array(sabC);
        // sabNumD = new Int16Array(sabD);
        // sabNumI = new Float64Array(sabI);
        // sabNumW = new Float64Array(sabW);
        // sabNumPos = new Uint16Array(sabPos);            
        // sabNumConnectome = new Float64Array(sabConnectome);
        // sabNumCom = new Int16Array(sabCom);

        sabNumAPtr = Module._malloc(neuronSize * Module.HEAPF64.BYTES_PER_ELEMENT)
        sabNumBPtr = Module._malloc(neuronSize * Module.HEAPF64.BYTES_PER_ELEMENT)
        sabNumCPtr = Module._malloc(neuronSize * Module.HEAP16.BYTES_PER_ELEMENT)
        sabNumDPtr = Module._malloc(neuronSize * Module.HEAP16.BYTES_PER_ELEMENT)
        sabNumIPtr = Module._malloc(neuronSize * Module.HEAPF64.BYTES_PER_ELEMENT)
        sabNumWPtr = Module._malloc(neuronSize * Module.HEAPF64.BYTES_PER_ELEMENT)
        sabNumConnectomePtr = Module._malloc(neuronSize * neuronSize * Module.HEAPF64.BYTES_PER_ELEMENT)

        let startsabNumAPtr = sabNumAPtr/Module.HEAPF64.BYTES_PER_ELEMENT;
        sabNumA = Module.HEAPF64.subarray( startsabNumAPtr, (startsabNumAPtr + neuronSize ));
        let startsabNumBPtr = sabNumBPtr/Module.HEAPF64.BYTES_PER_ELEMENT;
        sabNumB = Module.HEAPF64.subarray( startsabNumBPtr, (startsabNumBPtr + neuronSize ));
        let startsabNumCPtr = sabNumCPtr/Module.HEAP16.BYTES_PER_ELEMENT;
        sabNumC = Module.HEAP16.subarray( startsabNumCPtr, (startsabNumCPtr + neuronSize ));
        let startsabNumDPtr = sabNumDPtr/Module.HEAP16.BYTES_PER_ELEMENT;
        sabNumD = Module.HEAP16.subarray( startsabNumDPtr, (startsabNumDPtr + neuronSize ));
        let startsabNumIPtr = sabNumIPtr/Module.HEAPF64.BYTES_PER_ELEMENT;
        sabNumI = Module.HEAPF64.subarray( startsabNumIPtr, (startsabNumIPtr + neuronSize ));
        let startsabNumWPtr = sabNumWPtr/Module.HEAPF64.BYTES_PER_ELEMENT;
        sabNumW = Module.HEAPF64.subarray( startsabNumWPtr, (startsabNumWPtr + neuronSize ));
        let startsabNumConnectomePtr = sabNumConnectomePtr/Module.HEAPF64.BYTES_PER_ELEMENT;
        sabNumConnectome = Module.HEAPF64.subarray( startsabNumConnectomePtr, (startsabNumConnectomePtr + neuronSize * neuronSize ));

        // sabNumPos = Module._malloc(1 * Module.HEAPF64.BYTES_PER_ELEMENT)
        // sabNumNeuronCircle = Module._malloc(neuronSize * Module.HEAP32.BYTES_PER_ELEMENT)

        simulationWorkerChannelPort = eventFromMain.data.simulationWorkerChannelPort;
        initializeChannelPort = eventFromMain.data.initializeChannelPort;
        abPrevNumNeuronCircle = new Int16Array(neuronSize);

        sabCom = eventFromMain.data.sabCom;
        sabConfig = eventFromMain.data.sabConfig;
        sabIsPlaying = eventFromMain.data.sabIsPlaying;

        sabNumCom = new Int16Array(sabCom);
        sabNumConfig = new Uint32Array(sabConfig);
        sabNumIsPlaying = new Int16Array(sabIsPlaying);

        console.log("Before ptr canvas buffer");

        ptrCanvasBuffer = Module._malloc(windowSize * Module.HEAPF64.BYTES_PER_ELEMENT);
        const startCanvas = ptrCanvasBuffer/Module.HEAPF64.BYTES_PER_ELEMENT;
        allocatedCanvasBuffer = Module.HEAPF64.subarray( startCanvas, (startCanvas + windowSize ));

        ptrPos = Module._malloc(1 * Module.HEAP16.BYTES_PER_ELEMENT);
        const startPos = ptrPos/Module.HEAP16.BYTES_PER_ELEMENT;
        sabNumPos = Module.HEAP16.subarray( startPos, (startPos + 1 ));

        ptrNeuronCircle = Module._malloc(neuronSize * Module.HEAP16.BYTES_PER_ELEMENT);
        const startNeuron = ptrNeuronCircle/Module.HEAP16.BYTES_PER_ELEMENT;
        sabNumNeuronCircle = Module.HEAP16.subarray( startNeuron, (startNeuron + neuronSize ));
    
        ptrNps = Module._malloc(1 * Module.HEAP32.BYTES_PER_ELEMENT);
        const startNps = ptrNps/Module.HEAP32.BYTES_PER_ELEMENT;
        console.log("ptrNps, startNps");
        console.log(ptrNps, startNps);
        sabNumNps = Module.HEAP32.subarray( startNps, (startNps + 1 ));


        const matrixSize = neuronSize * neuronSize;
        ptrVisPrefs = Module._malloc( matrixSize * Module.HEAP16.BYTES_PER_ELEMENT);
        const startVisPrefs = ptrVisPrefs/Module.HEAP16.BYTES_PER_ELEMENT;
        sabVisPrefs = Module.HEAP16.subarray( startVisPrefs, (startVisPrefs + matrixSize ));

        // vision
        ptrVisPrefVals = Module._malloc(VisPrefsLength * totalCamera * Module.HEAPF64.BYTES_PER_ELEMENT);
        const startVisPrefVals = ptrVisPrefVals/Module.HEAPF64.BYTES_PER_ELEMENT;
        sabVisPrefVals = Module.HEAPF64.subarray( startVisPrefVals, (startVisPrefVals + VisPrefsLength * totalCamera ));

        ptrMotorCommands = Module._malloc(MotorCommandsLength * Module.HEAPF64.BYTES_PER_ELEMENT);
        const startMotorCommands = ptrMotorCommands/Module.HEAPF64.BYTES_PER_ELEMENT;
        sabMotorCommands = Module.HEAPF64.subarray( startMotorCommands, (startMotorCommands + MotorCommandsLength ));

        ptrNeuronContacts = Module._malloc(matrixSize * Module.HEAPF64.BYTES_PER_ELEMENT);
        const startNeuronContacts = ptrNeuronContacts/Module.HEAPF64.BYTES_PER_ELEMENT;
        sabNeuronContacts = Module.HEAPF64.subarray( startNeuronContacts, (startNeuronContacts + matrixSize ));

        ptrCameraDrawBuffer = Module._malloc( cameraWidth * cameraHeight * COLOR_CHANNELS * CAMERA_BYTES_PER_ELEMENT );
        const startCameraBuffer = ptrCameraDrawBuffer/Module.HEAPU8.BYTES_PER_ELEMENT;
        sabCameraDrawBuffer = Module.HEAPU8.subarray(startCameraBuffer, startCameraBuffer + cameraWidth * cameraHeight * COLOR_CHANNELS);

        ptrStateBuffer = Module._malloc( StateLength * Module.HEAP32.BYTES_PER_ELEMENT );
        const startStateBuffer = ptrStateBuffer/Module.HEAP32.BYTES_PER_ELEMENT;
        sabStateBuffer = Module.HEAP32.subarray(startStateBuffer, startStateBuffer + StateLength);
        
        ptrMotorMessage = Module._malloc( MotorMessageLength * CAMERA_BYTES_PER_ELEMENT );
        const startMotorMessageBuffer = ptrMotorMessage/Module.HEAPU8.BYTES_PER_ELEMENT;
        sabMotorMessageBuffer = Module.HEAPU8.subarray(startMotorMessageBuffer, startMotorMessageBuffer + MotorMessageLength);

        // ptrStateBuffer | WS, PreProcess CV, Neuron Simulation, UI
        // ptrMotorCommands | WS, Neuron Simulation
        // ptrCameraDrawBuffer | WS, UI, PreProcess CV, 
        // ptrVisPrefs | UI, PreProcessCV, 
        // ptrVisPrefVals | UI, PreProcessCV
        // Vis Prefs&Vals create connectomeCV like connectome but for 

    
        console.log("b4 pass ptr");        
        const test = Module.ccall(
            'passPointers',
            'number',
            [
                'number', 'number' ,'number','number','number','number', 'number', 'number', 'number',
            ],
            [
                ptrCanvasBuffer, ptrPos, ptrNeuronCircle, ptrNps, ptrStateBuffer, ptrVisPrefs, ptrVisPrefVals, ptrMotorMessage, ptrNeuronContacts
            ]
        );
        console.log("after pass ptr", ptrMotorCommands);        
        
        initializeChannelPort.postMessage({
            message:'ALLOCATED_BUFFER',
            allocatedCanvasbuffer: allocatedCanvasBuffer,
            sabNumNeuronCircle: sabNumNeuronCircle,
            sabNumNps: sabNumNps,
            sabVisPrefs: sabVisPrefs,
            sabVisPrefVals: sabVisPrefVals,
            sabNeuronContacts: sabNeuronContacts,
            sabMotorCommands: sabMotorCommands,

            sabNumA : sabNumA,
            sabNumB : sabNumB,
            sabNumC : sabNumC,
            sabNumD : sabNumD,
            sabNumI : sabNumI,
            sabNumW : sabNumW,
            sabNumPos : sabNumPos,
            sabNumConnectome : sabNumConnectome,
            // sabNumNeuronCircle : sabNumNeuronCircle,
            sabNumConfig : sabNumConfig,
            sabNumCom : sabNumCom,
            sabNumIsPlaying : sabNumIsPlaying,            
        });
        await sleep(1700);

        // console.log(sabNumA,isPlaying);
        console.log(sabNumA,sabNumB,sabNumC, sabNumD, sabNumI, sabNumW, canvasBuffers, sabNumPos, sabNumConnectome, level, neuronSize,envelopeSize,bufferSize,isPlaying);
        console.log(sabNumAPtr, sabNumBPtr, sabNumCPtr, sabNumDPtr,   sabNumIPtr, sabNumWPtr, sabNumConnectomePtr, level, neuronSize, envelopeSize, bufferSize, isPlaying);
        
    }else
    if (eventFromMain.data.message === 'RUN_WORKER') {
        let running = 0;
        try{
            await sleep(1700);
            Module.ccall(
                'changeNeuronSimulatorProcess',
                'number',
                ['number', 'number' ,'number','number',  'number', 'number' ,'number',
                    'number', 'number' ,'number','number','number', 'number', 'number', 'number'],
                [ sabNumAPtr, sabNumBPtr, sabNumCPtr, sabNumDPtr,   sabNumIPtr, sabNumWPtr, sabNumConnectomePtr,
                    level, neuronSize, envelopeSize, bufferSize, isPlaying, ptrVisPrefs, ptrMotorCommands, sabNeuronContacts]
            );
            // EXTERNC FUNCTION_ATTRIBUTE double changeNeuronSimulatorProcess(double *_a, double *_b, short *_c, short *_d, double *_i, double *_w, double *_connectome,
            //     short _level, int32_t _neuronLength, int32_t _envelopeSize, int32_t _bufferSize, short _isPlaying, 
            //     short *vis_prefs, double *_motor_command, double *_neuronContacts,
            //     void (*onRequest)(const char*)){      // platform_log2("changeNeuronSimulatorProcess 0");
            
            // running = Module.changeNeuronSimulatorProcess(level, neuronSize,envelopeSize,bufferSize,isPlaying);
        }catch(ex){
            console.log(ex);
        }
    
        console.log("Neuron", running);
        isConnectedAllocateBuffer = true;
    
        await sleep(500);
        simulationWorkerChannelPort.postMessage({
            message:'INITIALIZED_WORKER',
            // ptrStateBuffer: ptrStateBuffer,
            // ptrCameraDrawBuffer: ptrCameraDrawBuffer,
            // ptrMotorCommands: ptrMotorCommands,
            // ptrVisPrefs: ptrVisPrefs,
            // ptrVisPrefVals: ptrVisPrefVals,
            sabStateBuffer: sabStateBuffer,
            sabCameraDrawBuffer: sabCameraDrawBuffer,
            sabMotorCommands: sabMotorCommands,
            sabMotorMessageBuffer: sabMotorMessageBuffer,
            sabVisPrefs: sabVisPrefs,
            sabVisPrefVals: sabVisPrefVals,
        });

        console.log("init end")

    }else
    if (eventFromMain.data.message === 'CONNECT_SIMULATION') {
        // isNotified = false;
        notif[0] = 100;
        // sabNumNps[0] = 101;
        
        console.log("connect simulation branch", sabNumNps[0]);

        let prevCircleFlag = false;
        console.log("Atomics start waiting 2", statesDraw);
        // console.log(Atomics.wait(statesDraw, 0, 0) === 'ok');
        const startNps = ptrNps / Module.HEAP32.BYTES_PER_ELEMENT;

        Module.changeIdxSelectedProcess(sabNumConfig[0]);
        // while (Atomics.wait(Module.HEAP32, startNps, 0) === 'ok') {
        // // while (Atomics.wait(sabNumNps, 0, 0) === 'ok') {
        //     console.log("Atomics not waiting anymore");
        //     // console.log(Atomics.wait(Module.HEAP32, startNps, 0) === 'ok');
        //     // Atomics.store(Module.HEAP32, startNps, 0);
        // }
    
        // while (true){
        //     if (sabNumConfig[0] != 0){
        //         console.log("init end con SAB NUM CONFIG" );
        //         selectedIdx = sabNumConfig[0];
        //         sabNumConfig[0] = 0;
        //         Module.changeIdxSelectedProcess(selectedIdx);
        //     }
        //     // selectedIdx=sabNumConfig[0];
        //     // let temp2 = Module.getCurrentPosition(0);
        //     // sabNumPos.fill(temp2);
        //     if (sabNumConfig[1]==1){
        //         Module.stopThreadProcess(0)
        //         sabNumConfig[1] = 0;
        //     }

        //     if (sabNumCom[0]==1){
        //         console.log("Instruction coming in!");
        //         sabNumCom[0] = -1;
        //     }
        //     if (sabNumIsPlaying[0]==-1 || sabNumIsPlaying[0]==1){
        //         Module.changeIsPlayingProcess(sabNumIsPlaying[0]);
        //         sabNumIsPlaying[0] = 0;
        //     }
        // }
    }else
    if (eventFromMain.data.message === 'CHANGE_SELECTED_IDX') {
    Module.changeIdxSelectedProcess(eventFromMain.data.selectedIdx);
    }

}  



self.importScripts("neuronprototype.js"); 
// importScripts("img_tracker_wasm.js"); 
self.Module.onRuntimeInitialized = async _ => {
    console.log("WASM Runtime Initialized", self.Module);
    postMessage({
        message:'INITIALIZE_WASM',
        // statesDrawBuffer : statesDrawBuffer,
    });
    // console.log("self.Module.myFunction");
    // console.log(self.Module.myFunction);
    // self.Module.myFunction( ()=>{
    //     console.log("notif[0]");
    // });
}; 

// callback from C++ can't access the same parent scope, so callback is not possible here
// what has been done
function updateMotorCommand(rawPosState, message, rawPosCmdLen, ptrMotorCommandMessage){
    const posNotify = rawPosState >> 2;
    // const posCmdLen = rawPosCmdLen;
    // const startMotorCommands = ptrMotorCommandMessage/Module.HEAPU8.BYTES_PER_ELEMENT;
    // if (!isNotified){
        // isNotified = true;
        // console.log("POS : ", HEAP32[posNotify + STATE.COMMAND_MOTORS_LENGTH], message, rawPosCmdLen, new TextDecoder("utf-8").decode(HEAPU8.slice(startMotorCommands, startMotorCommands + posCmdLen) ));
    // }
    // console.log("HEAPU8[posCmd] : ", HEAPU8.subarray(posCmd, posCmd + posCmdLen));
    Atomics.notify(HEAP32, posNotify + STATE.COMMAND_MOTORS,1);
}


function callWorkerThread(a){
    // console.log("callme");
    const pos = a>>2;
    // console.log("pos", pos);
    // if (HEAP32[pos] == 101){
        // HEAP32[pos] = 200;
        
        // Atomics.notify(HEAP32, pos,1);
        // console.log(HEAP32[pos]);
    // }
    // console.log(a >> 2);
    // statesDraw[0] = 1;
    // Atomics.store(statesDraw, 0, 0);
    // console.log("CALL ME RECEIVED IN WEB WORKER 2", notif[0]);
    // console.log("channel port", initializeChannelPort);
    // if (!isNotified){

    // if (notif[0]==100){

    //     console.log("statesDraw")
    //     // console.log(statesDraw)
    //     Atomics.notify(statesDraw, 0, 1);
    // }
    // console.log(self);
    // postMessage("CALL MEEEEE");
    
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
