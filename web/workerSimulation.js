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

let ptrVisPrefs;
let ptrMotorCommands;
let ptrNeuronContacts;
let sabVisPrefs;
let sabMotorCommands;
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
        sabNumNps = Module.HEAP32.subarray( startNps, (startNps + 1 ));

        ptrVisPrefs = Module._malloc(10 * Module.HEAP16.BYTES_PER_ELEMENT);
        const startVisPrefs = ptrPos/Module.HEAP16.BYTES_PER_ELEMENT;
        sabVisPrefs = Module.HEAP16.subarray( startVisPrefs, (startVisPrefs + 10 ));

        ptrMotorCommands = Module._malloc(10 * Module.HEAP16.BYTES_PER_ELEMENT);
        const startMotorCommands = ptrMotorCommands/Module.HEAP16.BYTES_PER_ELEMENT;
        sabMotorCommands = Module.HEAP16.subarray( startMotorCommands, (startMotorCommands + 10 ));

        ptrNeuronContacts = Module._malloc(10 * Module.HEAP16.BYTES_PER_ELEMENT);
        const startNeuronContacts = ptrNeuronContacts/Module.HEAP16.BYTES_PER_ELEMENT;
        sabNeuronContacts = Module.HEAP16.subarray( startNeuronContacts, (startNeuronContacts + 10 ));
    
        console.log("b4 pass ptr");        
        const test = Module.ccall(
            'passPointers',
            'number',
            [
                'number', 'number' ,'number','number',
            ],
            [
                ptrCanvasBuffer, ptrPos, ptrNeuronCircle, ptrNps,
            ]
        );
        console.log("after pass ptr", test);        
        
        initializeChannelPort.postMessage({
            message:'ALLOCATED_BUFFER',
            allocatedCanvasbuffer: allocatedCanvasBuffer,
            sabNumNeuronCircle: sabNumNeuronCircle,
            sabNumNps: sabNumNps,

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
                    level, neuronSize, envelopeSize, bufferSize, isPlaying, sabVisPrefs,sabMotorCommands, sabNeuronContacts]
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
            message:'INITIALIZED_WORKER'
        });

        console.log("init end")

    }else
    if (eventFromMain.data.message === 'CONNECT_SIMULATION') {
        console.log("connect simulation branch")

        let prevCircleFlag = false;

        while (true){
            // console.log("init end con" )
            if (sabNumConfig[0] != 0){
                selectedIdx = sabNumConfig[0];
                sabNumConfig[0] = 0;
                Module.changeIdxSelectedProcess(selectedIdx);
            }
            // selectedIdx=sabNumConfig[0];
            // let temp2 = Module.getCurrentPosition(0);
            // sabNumPos.fill(temp2);
            if (sabNumConfig[1]==1){
                Module.stopThreadProcess(0)
                sabNumConfig[1] = 0;
            }

            if (sabNumCom[0]==1){
                console.log("Instruction coming in!");
                sabNumCom[0] = -1;
            }
            if (sabNumIsPlaying[0]==-1 || sabNumIsPlaying[0]==1){
                Module.changeIsPlayingProcess(sabNumIsPlaying[0]);
                sabNumIsPlaying[0] = 0;
            }
        }
    }
}  



self.importScripts("neuronprototype.js"); 
self.Module.onRuntimeInitialized = async _ => {
    console.log("WASM Runtime Initialized");
    postMessage({
        message:'INITIALIZE_WASM',
    });
}; 

function callMe(a){
    console.log(tempBufferNum.subarray(0,10));
    
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
