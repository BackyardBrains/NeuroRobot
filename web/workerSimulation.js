const COLOR_CHANNELS = 3;
const CAMERA_BYTES_PER_ELEMENT = 1;
const MotorCommandsLength = 6 * 2;
const MotorMessageLength = 300;
const StateLength = 70;
const cameraWidth = 320;
const cameraHeight = 240;
const commandPerSecond = 70;
let curCommandPerSecond = 0;
let bufferSimulationMessage = [];
let periodicNeuronSpikingFlags;

const visualInputLen = 22;
let visualInputLength;


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


// websocket
let ptrCameraDrawBuffer;
let ptrStateBuffer;
let sabCameraDrawBuffer;
let sabStateBuffer;
let isNotified = false;


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

// START SIMULATOR
let ptrNeuronTypeBuf;
let ptrDelayNeuronBuf;

let sabNeuronTypeBuf;
let sabDelayNeuronBuf;
// START SIMULATOR

// PASS POINTER
let ptrDistPrefs;
let ptrSpeakerBuf;
let ptrMicrophoneBuf;
let ptrLedBuf;
let ptrLedPosBuf;
let ptrVisualInputBuf;

let sabDistPrefs;
let sabSpeakerBuf;
let sabMicrophoneBuf;
let sabLedBuf;
let sabLedPosBuf;
let sabVisualInputBuf;
// PASS POINTER

// PASS INPUT
let bufDistanceCount = 1;
let bufDistanceLimitCount = 100;
let ptrDistanceBuf;
let ptrDistanceMinLimitBuf;
let ptrDistanceMaxLimitBuf;

let sabDistanceBuf;
let sabDistanceMinLimitBuf;
let sabDistanceMaxLimitBuf;
// PASS INPUT


// short *p_dist_prefs, short *p_speaker_buf, short *p_microphone_buf, short *p_led_buf, short *p_led_pos_buf, double *p_visual_input_buf){

// let tempBuffer = new SharedArrayBuffer( bufSize * Float64Array.BYTES_PER_ELEMENT )
// let tempBufferNum = new Float64Array(tempBuffer);
let canvasBuffers = [];
let canvasBuffersNum = [];

const level = 1;
const envelopeSize = 200;
const bufferSize = 200 * 30;
let isPlaying = 1;


var vm = self;
// var tempOnMessage = self.onmessage;
self.onmessage = async function( eventFromMain ) {
    console.log("eventFromMain.data.message");
    console.log(eventFromMain.data.message);
    if (eventFromMain.data.message === 'STOP_THREAD_PROCESS') {
        console.log("Module.stopThreadProcess ");
        Module.stopThreadProcess(0);
        sabNumConfig[1] = 0;
        postMessage({
            message:'STOP_THREADS',
        });
    } else
    if (eventFromMain.data.message === 'INITIALIZE_WORKER') {
        console.log("Initialize Worker branch", neuronSize);
        neuronSize = eventFromMain.data.neuronSize;
        const matrixSize = neuronSize * neuronSize;

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

        sabNumAPtr = Module._malloc(neuronSize * Module.HEAPF64.BYTES_PER_ELEMENT);
        sabNumBPtr = Module._malloc(neuronSize * Module.HEAPF64.BYTES_PER_ELEMENT);
        sabNumCPtr = Module._malloc(neuronSize * Module.HEAP16.BYTES_PER_ELEMENT);
        sabNumDPtr = Module._malloc(neuronSize * Module.HEAP16.BYTES_PER_ELEMENT);
        sabNumIPtr = Module._malloc(neuronSize * Module.HEAPF64.BYTES_PER_ELEMENT);
        sabNumWPtr = Module._malloc(neuronSize * Module.HEAPF64.BYTES_PER_ELEMENT);
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

        // START SIMULATION
        ptrNeuronTypeBuf = Module._malloc(neuronSize * Module.HEAP16.BYTES_PER_ELEMENT);
        ptrDelayNeuronBuf = Module._malloc(neuronSize * Module.HEAP16.BYTES_PER_ELEMENT);

        let startsabNeuronTypeBuf = ptrNeuronTypeBuf/Module.HEAP16.BYTES_PER_ELEMENT;
        let startsabDelayNeuronBuf = ptrDelayNeuronBuf/Module.HEAP16.BYTES_PER_ELEMENT;

        sabNeuronTypeBuf = Module.HEAP16.subarray(startsabNeuronTypeBuf, (startsabNeuronTypeBuf + neuronSize));
        sabDelayNeuronBuf = Module.HEAP16.subarray(startsabDelayNeuronBuf, (startsabDelayNeuronBuf + neuronSize));
        // START SIMULATION


        // START PASS POINTER       
        visualInputLength = (neuronSize) * visualInputLen;
        ptrDistPrefs = Module._malloc(matrixSize * Module.HEAP16.BYTES_PER_ELEMENT);
        ptrSpeakerBuf = Module._malloc(matrixSize * Module.HEAP16.BYTES_PER_ELEMENT);
        ptrMicrophoneBuf = Module._malloc(matrixSize * Module.HEAP16.BYTES_PER_ELEMENT);
        ptrLedBuf = Module._malloc(matrixSize * Module.HEAP16.BYTES_PER_ELEMENT);
        ptrLedPosBuf = Module._malloc(matrixSize * Module.HEAP16.BYTES_PER_ELEMENT);
        ptrVisualInputBuf = Module._malloc(visualInputLength * neuronSize * Module.HEAPF64.BYTES_PER_ELEMENT);

        let startsabDistPrefsPtr = ptrDistPrefs/Module.HEAP16.BYTES_PER_ELEMENT;
        let startsabSpeakerBufPtr = ptrSpeakerBuf/Module.HEAP16.BYTES_PER_ELEMENT;
        let startsabMicrophoneBufPtr = ptrMicrophoneBuf/Module.HEAP16.BYTES_PER_ELEMENT;
        let startsabLedBufPtr = ptrLedBuf/Module.HEAP16.BYTES_PER_ELEMENT;
        let startsabLedPosBufPtr = ptrLedPosBuf/Module.HEAP16.BYTES_PER_ELEMENT;
        let startsabVisualInputBufPtr = ptrVisualInputBuf/Module.HEAPF64.BYTES_PER_ELEMENT;

        sabDistPrefs = Module.HEAP16.subarray(startsabDistPrefsPtr, (startsabDistPrefsPtr + matrixSize));
        sabSpeakerBuf = Module.HEAP16.subarray(startsabSpeakerBufPtr, (startsabSpeakerBufPtr + matrixSize));
        sabMicrophoneBuf = Module.HEAP16.subarray(startsabMicrophoneBufPtr, (startsabMicrophoneBufPtr + matrixSize));
        sabLedBuf = Module.HEAP16.subarray(startsabLedBufPtr, (startsabLedBufPtr + matrixSize));
        sabLedPosBuf = Module.HEAP16.subarray(startsabLedPosBufPtr, (startsabLedPosBufPtr + matrixSize));
        sabVisualInputBuf = Module.HEAPF64.subarray(startsabVisualInputBufPtr, (startsabVisualInputBufPtr + visualInputLength));
        // END PASS POINTER

        // START PASS INPUT
        // distanceBuf, distanceMinLimitBuf, distanceMaxLimitBuf        
        ptrDistanceBuf = Module._malloc(bufDistanceCount * Module.HEAPF64.BYTES_PER_ELEMENT);
        ptrDistanceMinLimitBuf = Module._malloc(bufDistanceLimitCount * Module.HEAP16.BYTES_PER_ELEMENT);
        ptrDistanceMaxLimitBuf = Module._malloc(bufDistanceLimitCount * Module.HEAP16.BYTES_PER_ELEMENT);

        let startsabDistanceBufPtr = ptrDistanceBuf/Module.HEAPF64.BYTES_PER_ELEMENT;
        let startsabDistanceMinLimitBufPtr = ptrDistanceMinLimitBuf/Module.HEAP16.BYTES_PER_ELEMENT;
        let startsabDistanceMaxLimitBufPtr = ptrDistanceMaxLimitBuf/Module.HEAP16.BYTES_PER_ELEMENT;

        sabDistanceBuf = Module.HEAPF64.subarray(startsabDistanceBufPtr, (startsabDistanceBufPtr + bufDistanceCount));
        sabDistanceMinLimitBuf = Module.HEAP16.subarray(startsabDistanceMinLimitBufPtr, (startsabDistanceMinLimitBufPtr + bufDistanceLimitCount));
        sabDistanceMaxLimitBuf = Module.HEAP16.subarray(startsabDistanceMaxLimitBufPtr, (startsabDistanceMaxLimitBufPtr + bufDistanceLimitCount));
        // END PASS INPUT

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


        ptrVisPrefs = Module._malloc( matrixSize * Module.HEAP16.BYTES_PER_ELEMENT);
        const startVisPrefs = ptrVisPrefs/Module.HEAP16.BYTES_PER_ELEMENT;
        sabVisPrefs = Module.HEAP16.subarray( startVisPrefs, (startVisPrefs + matrixSize ));

        // vision
        // ptrVisPrefVals = Module._malloc(VisPrefsLength * totalCamera * Module.HEAPF64.BYTES_PER_ELEMENT);
        // const prefCameraLength = visualInputLen * 2;
        const prefCameraLength = visualInputLen * neuronSize;
        ptrVisPrefVals = Module._malloc(prefCameraLength * Module.HEAPF64.BYTES_PER_ELEMENT);
        const startVisPrefVals = ptrVisPrefVals/Module.HEAPF64.BYTES_PER_ELEMENT;
        // sabVisPrefVals = Module.HEAPF64.subarray( startVisPrefVals, (startVisPrefVals + VisPrefsLength * totalCamera ));
        sabVisPrefVals = Module.HEAPF64.subarray( startVisPrefVals, (startVisPrefVals + prefCameraLength ));

        // ptrMotorCommands = Module._malloc(MotorCommandsLength * Module.HEAPU8.BYTES_PER_ELEMENT);
        // const startMotorCommands = ptrMotorCommands/Module.HEAPU8.BYTES_PER_ELEMENT;
        // sabMotorCommands = Module.HEAPU8.subarray( startMotorCommands, (startMotorCommands + MotorCommandsLength ));

        ptrMotorMessage = Module._malloc( MotorMessageLength * CAMERA_BYTES_PER_ELEMENT );
        const startMotorMessageBuffer = ptrMotorMessage/Module.HEAPU8.BYTES_PER_ELEMENT;
        // sabMotorMessageBuffer = Module.HEAPU8.subarray(startMotorMessageBuffer, startMotorMessageBuffer + MotorMessageLength);
        sabMotorCommands = Module.HEAPU8.subarray(startMotorMessageBuffer, startMotorMessageBuffer + MotorMessageLength);

        ptrNeuronContacts = Module._malloc(matrixSize * Module.HEAPF64.BYTES_PER_ELEMENT);
        const startNeuronContacts = ptrNeuronContacts/Module.HEAPF64.BYTES_PER_ELEMENT;
        sabNeuronContacts = Module.HEAPF64.subarray( startNeuronContacts, (startNeuronContacts + matrixSize ));

        ptrCameraDrawBuffer = Module._malloc( cameraWidth * cameraHeight * COLOR_CHANNELS * CAMERA_BYTES_PER_ELEMENT );
        const startCameraBuffer = ptrCameraDrawBuffer/Module.HEAPU8.BYTES_PER_ELEMENT;
        sabCameraDrawBuffer = Module.HEAPU8.subarray(startCameraBuffer, startCameraBuffer + cameraWidth * cameraHeight * COLOR_CHANNELS);

        ptrStateBuffer = Module._malloc( StateLength * Module.HEAP32.BYTES_PER_ELEMENT );
        const startStateBuffer = ptrStateBuffer/Module.HEAP32.BYTES_PER_ELEMENT;
        sabStateBuffer = Module.HEAP32.subarray(startStateBuffer, startStateBuffer + StateLength);
        // sabStateBuffer = new Int32Array(new SharedArrayBuffer(StateLength * Int32Array.BYTES_PER_ELEMENT));
        
        ptrPeriodicNeuronSpikingFlags = Module._malloc( neuronSize * Module.HEAP32.BYTES_PER_ELEMENT );
        const startPeriodicNeuronSpikingFlags = ptrPeriodicNeuronSpikingFlags/Module.HEAP32.BYTES_PER_ELEMENT;
        periodicNeuronSpikingFlags = Module.HEAP32.subarray(startPeriodicNeuronSpikingFlags, startPeriodicNeuronSpikingFlags + neuronSize);
        // console.log("POINTER000 periodicNeuronSpikingFlags: ", startPeriodicNeuronSpikingFlags);

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
                'number', 'number' ,'number','number','number','number',
            ],
            [
                ptrCanvasBuffer, ptrPos, ptrNeuronCircle, ptrNps, ptrStateBuffer, ptrVisPrefs, ptrVisPrefVals, ptrMotorMessage, ptrNeuronContacts,
                ptrDistPrefs, ptrSpeakerBuf, ptrMicrophoneBuf, ptrLedBuf, ptrLedPosBuf, ptrVisualInputBuf
            ]
        );
        Module.ccall(
            'passInput',
            'number',
            [
                'number', 'number' ,'number'
            ],
            [
                ptrDistanceBuf, ptrDistanceMinLimitBuf, ptrDistanceMaxLimitBuf
            ]
        ); // double *p_sensor_distance, short *p_sensor_min_limit, short *p_sensor_max_limit
        Module.ccall(
            'passWebParameters',
            'number',
            [
                'number',
            ],
            [
                ptrPeriodicNeuronSpikingFlags,
            ]
        );         
        // distanceBuf, distanceMinLimitBuf, distanceMaxLimitBuf
        // int bufDistanceCount = 1;
        // int bufDistanceLimitCount = 100;
      
        // passPointers(double *_canvasBuffer, short *_positions, short *_neuronCircle,int *_nps, int *p_state_buf, short *p_vis_prefs, double *p_vis_pref_vals, uint8_t *p_motor_command_message,double *p_neuron_contacts,
        // short *p_dist_prefs, short *p_speaker_buf, short *p_microphone_buf, short *p_led_buf, short *p_led_pos_buf, double *p_visual_input_buf){
        
        // passPointers(double *_canvasBuffer, short *_positions, short *_neuronCircle,int *_nps, int *p_state_buf, 
        // short *p_vis_prefs, double *p_vis_pref_vals, uint8_t *p_motor_command_message,double *p_neuron_contacts, 
        // short *p_dist_prefs, short *p_speaker_buf, short *p_microphone_buf, short *p_led_buf, short *p_led_pos_buf, double *p_visual_input_buf){
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
            

            // PASS POINTER & INPUT & RUNSIMULATION
            sabNeuronTypeBuf : sabNeuronTypeBuf,
            sabDelayNeuronBuf : sabDelayNeuronBuf,
            sabDistPrefs: sabDistPrefs,
            sabSpeakerBuf: sabSpeakerBuf,
            sabMicrophoneBuf: sabMicrophoneBuf,
            sabLedBuf: sabLedBuf,
            sabLedPosBuf: sabLedPosBuf,
            sabVisualInputBuf: sabVisualInputBuf,

            sabDistanceBuf: sabDistanceBuf,
            sabDistanceMinLimitBuf: sabDistanceMinLimitBuf,
            sabDistanceMaxLimitBuf: sabDistanceMaxLimitBuf,
            periodicNeuronSpikingFlags: periodicNeuronSpikingFlags
            // PASS POINTER & INPUT & RUNSIMULATION
            
        });
        await sleep(1700);

        // console.log(sabNumA,isPlaying);
        // console.log("!!!sabNumA,sabNumB,sabNumC, sabNumD, sabNumI, sabNumW, canvasBuffers, sabNumPos, sabNumConnectome, level, neuronSize,envelopeSize,bufferSize,isPlaying");
        // console.log(sabNumA,sabNumB,sabNumC, sabNumD, sabNumI, sabNumW, canvasBuffers, sabNumPos, sabNumConnectome, level, neuronSize,envelopeSize,bufferSize,isPlaying);
        // console.log(sabNumAPtr, sabNumBPtr, sabNumCPtr, sabNumDPtr,   sabNumIPtr, sabNumWPtr, sabNumConnectomePtr, level, neuronSize, envelopeSize, bufferSize, isPlaying);
        
    }else
    if (eventFromMain.data.message === 'RUN_WORKER') {
        let running = 0;
        try{
            await sleep(1700);
            Module.ccall(
                'changeNeuronSimulatorProcess',
                'number',
                ['number', 'number' ,'number','number',  'number', 'number' ,'number', //7
                    'number', 'number' ,'number','number','number', 'number', 'number', 'number',//8
                    'number', 'number' ,'number','number',
                ], 
                [ sabNumAPtr, sabNumBPtr, sabNumCPtr, sabNumDPtr,   sabNumIPtr, sabNumWPtr, sabNumConnectomePtr,
                    level, neuronSize, envelopeSize, bufferSize, isPlaying, ptrVisPrefs, ptrMotorCommands, sabNeuronContacts,
                    ptrNeuronTypeBuf, ptrDelayNeuronBuf, ptrDelayNeuronBuf, ptrDelayNeuronBuf,
                ]
            );
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
            sabVisPrefs: sabVisPrefs,
            sabVisPrefVals: sabVisPrefVals,
        });

        console.log("init end");
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

/// CONGRATS it is updating the motor command;
const empty = [];
const multiplierConstant = 0.78;
const multiplierAdjusterConstant = 0.5;

let diodeStatusMax = [];
const normalNeuronStartIdx = 12;

function updateMotorCommand(rawPosState, message, rawPosCmdLen, ptrMotorCommandMessage, neuronSize, ptrPeriodicNeuronSpikingFlags){
    const posNotify = rawPosState >> 2;
    // const posCmdLen = rawPosCmdLen;
    // const startMotorCommands = ptrMotorCommandMessage/Module.HEAPU8.BYTES_PER_ELEMENT;
    // if (!isNotified){
        // isNotified = true;
        // console.log("POS : ", HEAP32[posNotify + STATE.COMMAND_MOTORS_LENGTH], message, rawPosCmdLen, new TextDecoder("utf-8").decode(HEAPU8.slice(startMotorCommands, startMotorCommands + posCmdLen) ));
    // }
    // console.log("HEAPU8[posCmd] : ", HEAPU8.subarray(posCmd, posCmd + posCmdLen));
    curCommandPerSecond++;
    if (curCommandPerSecond == commandPerSecond) {
        // console.log("curCommandPerSecond : ", curCommandPerSecond);
        let infoStatusMax = [0, 0, 0, 0, 0, 0, 0];

        diodeStatusMax = [
          [0, 0, 0],
          [0, 0, 0],
          [0, 0, 0],
          [0, 0, 0],
        ];

        let diodeCounter = 0;
        const leftAttentionValue = {};
        const rightAttentionValue = {};
        let leftSumValue = 0;
        let rightSumValue = 0;

        let neuronSpikingFlags = new Int32Array(neuronSize);

        
        const commands = bufferSimulationMessage;
        const len = commands.length;
        let leftValidValueCounter = 0;
        let rightValidValueCounter = 0;
        for (let i = 0; i < len; i++) {
            const arr = commands[i].split(";");
            const n = arr.length;
            for (let j = 0; j < n; j++) {
                const arrStr = arr[j].split(":");
                if (arrStr[0] == "l") {
                    const val = parseInt(arrStr[1]);
                    if (Math.abs(val) >= 5) {
                        leftValidValueCounter++;
                        leftSumValue += val;
                    }
                    if (leftAttentionValue[val] == null) {
                        leftAttentionValue[val] = 1;
                    } else {
                        leftAttentionValue[val] = (leftAttentionValue[val]) + 1;
                    }
                } else if (arrStr[0] == "r") {
                    const val = parseInt(arrStr[1]);
                    if (Math.abs(val) >= 5) {
                        rightValidValueCounter++;
                        rightSumValue += val;
                    }
                    if (rightAttentionValue[val] == null) {
                        rightAttentionValue[val] = 1;
                    } else {
                        rightAttentionValue[val] = (rightAttentionValue[val]) + 1;
                    }
                } else if (arrStr[0] == "s") {
                    infoStatusMax[2] =
                        Math.max(infoStatusMax[2], parseInt(arrStr[1]));
                } else if (arrStr[0] == "n") {
                    const spikingFlags = arrStr[1].split("|");
                    for (let k = 0; k < spikingFlags.length; k++) {
                        neuronSpikingFlags[k] = Math.max(neuronSpikingFlags[k], parseInt(spikingFlags[k]));
                    }
                } else if (arrStr[0] == "d") {
                    const diodeSplit = arrStr[1].split(",");
                    diodeCounter = parseInt(diodeSplit[0]);

                    diodeStatusMax[diodeCounter][0] = Math.max(
                        diodeStatusMax[diodeCounter][0],
                        parseInt(diodeSplit[1]));
                    diodeStatusMax[diodeCounter][1] = Math.max(
                        diodeStatusMax[diodeCounter][1],
                        parseInt(diodeSplit[2]));
                    diodeStatusMax[diodeCounter][2] = Math.max(
                        diodeStatusMax[diodeCounter][2],
                        parseInt(diodeSplit[3]));
                }
            }
        }
        let diodeString = "";

        for (let c = 0; c < 4; c++) {
          diodeString =
              `${diodeString}d:${c},${diodeStatusMax[c][0]},${diodeStatusMax[c][1]},${diodeStatusMax[c][2]};`;
        }
        let avgLeft = 0;
        let avgRight = 0;
        let msg = "";
        if (leftAttentionValue[0] == len) {
            avgLeft = 0;
        } else {
            leftSumValue = leftSumValue / leftValidValueCounter;
            const calculatedValue = Math.sign(leftSumValue) *
                ((Math.abs(leftSumValue) - 250) * multiplierConstant + 250);
            // print("calculatedValue left");
            // print(calculatedValue);
            avgLeft = Math.floor(calculatedValue);
        }
        if (rightAttentionValue[0] == len) {
            avgRight = 0;
        } else {
            rightSumValue = rightSumValue / rightValidValueCounter;
            const calculatedValue = Math.sign(rightSumValue) *
                ((Math.abs(rightSumValue) - 250) * multiplierConstant + 250);
            avgRight = Math.floor(calculatedValue);
        }
        msg =
            `l:${avgLeft};r:${avgRight};s:${infoStatusMax[2]};` + diodeString;
        // msg =
        //     `l:50;r:20;s:4000;`+ diodeString;

        // if (avgLeft > 0 || avgRight > 0) {
        //     console.log("msg MOTOR TRIGGERED: ", msg);
        // }

        const bufferSize = msg.length;
        const stateLen = Object.keys(STATE).length;
        // console.log("sabStateBuffer : ", stateLen, sabStateBuffer, msg, curCommandPerSecond); //, bufferSimulationMessage
        if (sabStateBuffer === undefined) {
            sabStateBuffer = HEAP32.subarray(posNotify, posNotify + stateLen);
        }
        if (sabMotorCommands === undefined) {
            const posCommand = ptrMotorCommandMessage;
            sabMotorCommands = HEAPU8.subarray(posCommand, posCommand + MotorMessageLength);
        }

        if (periodicNeuronSpikingFlags === undefined) {
            const posPeriodicNeuronSpikingFlags = ptrPeriodicNeuronSpikingFlags >> 2;
            periodicNeuronSpikingFlags = HEAP32.subarray(posPeriodicNeuronSpikingFlags, posPeriodicNeuronSpikingFlags + neuronSize);
        }


        if (periodicNeuronSpikingFlags !== undefined) {
            periodicNeuronSpikingFlags.set(neuronSpikingFlags);
            // periodicNeuronSpikingFlags.fill(1);
            // console.log("POINTER periodicNeuronSpikingFlags: ", ptrPeriodicNeuronSpikingFlags);
        }



        sabStateBuffer[STATE.COMMAND_MOTORS_LENGTH] = bufferSize;
        if (sabMotorCommands !== undefined) {
            // console.log("message", msg);
            for (let i = 0; i < bufferSize; i++) {
                sabMotorCommands[i] = msg.charCodeAt(i);
            }
        }
        // console.log("ptrMotorCommandMessage", bufferSize, msg);
        // console.log("ptrMotorCommandMessage", message, rawPosCmdLen, ptrMotorCommandMessage);
        Atomics.notify(HEAP32, posNotify + STATE.COMMAND_MOTORS,1);

        curCommandPerSecond = 0;
        bufferSimulationMessage = [];

    // if (isIsolateWritePortInitialized) {
        //   _DesignBrainPageState.isolateWritePort.send(msg);
        // }

        // passToNeuronPostDelayed
        // try {
        //   for (let i = normalNeuronStartIdx; i < neuronSize; i++) {
        //     const neuronIndex = i;
        //     if (periodicNeuronSpikingFlags[i - normalNeuronStartIdx] == 1) {
        //       if (controller.nucleusList != null &&
        //           controller.nucleusList!.length > normalNeuronStartIdx) {
        //         controller.nucleusList![neuronIndex].isSpiking = 1;
        //       }
        //       // protoNeuron.circles[neuronIndex].isSpiking = 1;
        //       neuronSpikeFlags[neuronIndex].value = Random().nextInt(10000);
        //       console.log("neuronSpikeFlags1");
        //       console.log(controller.nucleusList!.length);
        //       // printDebug(neuronSpikeFlags);
        //     } else {
        //       try {
        //         // protoNeuron.circles[neuronIndex].isSpiking = -1;
        //         if (controller.nucleusList != null &&
        //             controller.nucleusList!.length > normalNeuronStartIdx) {
        //           controller.nucleusList![neuronIndex].isSpiking = -1;
        //         }

        //         neuronSpikeFlags[neuronIndex].value =
        //             Random().nextInt(10000);
        //         // printDebug("neuronSpikeFlags2");
        //         // printDebug(neuronSpikeFlags);
        //       } catch (err) {
        //         console.log("err neuronSpikeFlags2");
        //         console.log(err);
        //       }
        //     }
        //   }
        // } catch (err) {
        //     console.log("err2");
        //     console.log(err);
        // }

    }  else {
        bufferSimulationMessage.push(message);
    }
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
