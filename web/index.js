// WebSocket
var lookup = {
    "person": "🧍",
    "backpack": "🎒",
    "bottle": "🧴", // 🍶 🍼 🍾
    "cup": "☕",
    "bowl": "🧍", // 🥣
    "banana": "🍌",
    "apple": "🍎",
    "orange": "🍊",
    "chair": "🪑", // 💺
    "couch": "🛋️",
    "potted plant": "🪴",
    "laptop": "💻",
    "cell phone": "📱",
    "book": "📒",
    "vase": "🏺",
    "Movement": "🏃",
};
var arrLookupEmoji = [
    "🧍",
    "🎒",
    "🧴", // 🍶 🍼 🍾
    "☕",
    "🧍", // 🥣
    "🍌",
    "🍎",
    "🍊",
    "🪑", // 💺
    "🛋️",
    "🪴",
    "💻",
    "📱",
    "📒",
    "🏺",
    "🏃",
];

const StateLength = 70;
var websocketWorker;
var preprocessWorker;
var websocketcommandWorker;
var isEngineWarmed = false;
var isPlaying = false;
// var ptrStateBuffer;
// var ptrCameraDrawBuffer;
// var ptrVisPrefs;
// var ptrVisPrefVals;

var sabStateBuffer;
var sabCameraDrawBuffer;
var sabVisPrefs;
var sabVisPrefVals;
var sabNeuronContacts; 
var sabMotorCommands;
var sabMotorMessageBuffer;
// PREPROCESS
var sabPreprocessCameraBuffer;
let sabCanvasBuffer;
var sabAiPreprocessCameraBuffer;
var sabAiBoundingBox;

var sabPreprocessColorDetection;
var sabPreprocessObjectDetection;

// START SIMULATION
var sabNeuronTypeBuf;
var sabDelayNeuronBuf;
// START SIMULATION

// PASS POINTER & INPUT 
var sabDistPrefs;
var sabSpeakerBuf;
var sabMicrophoneBuf;
var sabLedBuf;
var sabLedPosBuf;
var sabVisualInputBuf;
var sabDistanceBuf;
var sabDistanceMinLimitBuf;
var sabDistanceMaxLimitBuf;
// PASS POINTER & INPUT 

// PASS UI POINTERS
var periodicNeuronSpikingFlags;
// PASS UI POINTERS



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


// WEB SOCKET 
const frameWidth = 320;
const frameHeight = 240;
let offscreenCanvas;
let ctxLeft;
let imgPerson;
let imgData;
let imgCamera;
let imgCameraLeft;

let canvasLeftElement;
let imgLeftFrame;
let imgFrame;
let lastFrameIdx= -100;

let canvasRightElement;
let ctxRight;

var izhikevichWorker;
let neuronSize = 2;
const windowSize = 200*30;
// let sabA;
// let sabB;
// let sabC;
// let sabD;
// let sabI;
// let sabW;
// let sabPos;
// let sabConnectome;
// let sabNeuronCircle;
let sabIsPlaying;
let sabCom;
let sabConfig = new SharedArrayBuffer( 10 * Uint32Array.BYTES_PER_ELEMENT );

let sabNumA;
let sabNumB;
let sabNumC;
let sabNumD;
let sabNumI;
let sabNumW;
let sabNumPos;
let sabNumConnectome;
let sabNumNeuronCircle;

let sabNumConfig = new Uint32Array(sabConfig);
let sabNumCom;
let sabNumIsPlaying;
let simulationWorkerChannel;
let initializeChannel;

let sabNumNps;
let tempJsonRawData;
// let sabCanvas=[];
// let canvasBuffers=[];
function initializeModels(jsonRawData){
    imgPerson = document.getElementById("imagePerson");
    imgPerson.src="http://127.0.0.1:5500/assets/icons/person.png";
    
    
    console.log("Initialize Models")
    tempJsonRawData = jsonRawData;
    try{
        izhikevichWorker.terminate();
    }catch(ex){
    }
    try{
        preprocessWorker.terminate();
    }catch(ex){
    }

    try{
        websocketWorker.terminate();
    }catch(ex){
    }

    try{
        recognitionWorker.terminate();
    }catch(ex){
    }
        


    console.log(jsonRawData);
    let jsonData = JSON.parse(jsonRawData);
    neuronSize = jsonData[9];
    // neuronSize = 200;
    // console.log("jsonData : ", jsonData);

    // sabA = new SharedArrayBuffer( neuronSize * Float64Array.BYTES_PER_ELEMENT );
    // sabB = new SharedArrayBuffer( neuronSize * Float64Array.BYTES_PER_ELEMENT );
    // sabC = new SharedArrayBuffer( neuronSize * Int16Array.BYTES_PER_ELEMENT );
    // sabD = new SharedArrayBuffer( neuronSize * Int16Array.BYTES_PER_ELEMENT );
    // sabI = new SharedArrayBuffer( neuronSize * Float64Array.BYTES_PER_ELEMENT );
    // sabW = new SharedArrayBuffer( neuronSize * Float64Array.BYTES_PER_ELEMENT );
    // sabPos = new SharedArrayBuffer( neuronSize * Uint32Array.BYTES_PER_ELEMENT );
    // sabConnectome = new SharedArrayBuffer( neuronSize * neuronSize * Float64Array.BYTES_PER_ELEMENT );
    // sabNeuronCircle = new SharedArrayBuffer( neuronSize * Int16Array.BYTES_PER_ELEMENT );
    
    // sabNumA = new Float64Array(sabA);
    // sabNumB = new Float64Array(sabB);
    // sabNumC = new Int16Array(sabC);
    // sabNumD = new Int16Array(sabD);
    // sabNumI = new Float64Array(sabI);
    // sabNumW = new Float64Array(sabW);
    // sabNumPos = new Uint16Array(sabPos);
    // sabNumConnectome = new Float64Array(sabConnectome);
    // sabNumNeuronCircle = new Int16Array(sabNeuronCircle);

    // sabConfig = new SharedArrayBuffer( 10 * Uint32Array.BYTES_PER_ELEMENT );
    sabCom = new SharedArrayBuffer( 1 * Int16Array.BYTES_PER_ELEMENT );
    sabIsPlaying = new SharedArrayBuffer( 1 * Int16Array.BYTES_PER_ELEMENT );
    
    sabPreprocessObjectDetection = new Float32Array(new SharedArrayBuffer( 7 * Float32Array.BYTES_PER_ELEMENT ));

    sabNumCom = new Int16Array(sabCom);
    // sabNumConfig = new Uint32Array(sabConfig);
    sabNumIsPlaying = new Int16Array(sabIsPlaying);
    
    simulationWorkerChannel = new MessageChannel();
    initializeChannel = new MessageChannel();

    izhikevichWorker = new Worker('build/web/workerSimulation.js');
    // sabCanvas = [];
    // canvasBuffers = [];
    // for (let i = 0;i<1;i++){
    //     let sab = new SharedArrayBuffer( windowSize * Float64Array.BYTES_PER_ELEMENT )        
    //     sabCanvas.push(sab);
    //     canvasBuffer.push(new Float64Array(sab));
    // }
    // canvasBuffer.push(sabNumPos)

    // sabNumA.fill(0.02);
    // sabNumB.fill(0.18);
    // sabNumC.fill(-65);
    // sabNumD.fill(2);
    // sabNumI.fill(5.0);
    // sabNumW.fill(2.0);
    /*
        setIzhikevichParameters(
            aBuf,bBuf,cBuf,dBuf,iBuf,wBuf,
            positionsBuf,connectomeBuf, level, neuronSize,envelopeSize,bufferSize,isPlaying){
    */

    // canvasBuffer.push(sabNumNeuronCircle);
    // canvasBuffer[0].fill(1);
    izhikevichWorker.onmessage=function(event){
        console.log(event.data);
        if (event.data.message == "INITIALIZE_WASM"){
            izhikevichWorker.postMessage({
                message:'INITIALIZE_WORKER',
                neuronSize:neuronSize,
                // sabA:sabA,
                // sabB:sabB,
                // sabC:sabC,
                // sabD:sabD,
                // sabI:sabI,
                // sabW:sabW,
                // sabPos:sabPos,
                // sabConnectome:sabConnectome,
                // sabCanvas:sabCanvas,
                // sabNeuronCircle:sabNeuronCircle,
                
                sabConfig:sabConfig,
                sabCom:sabCom,
                sabIsPlaying:sabIsPlaying,
                simulationWorkerChannelPort:simulationWorkerChannel.port1,
                initializeChannelPort:initializeChannel.port1,
            },[simulationWorkerChannel.port1, initializeChannel.port1]);
        }else
        if (event.data.message == "STOP_THREADS"){
            if (isEngineWarmed) {
                preprocessWorker.terminate();
                recognitionWorker.terminate();
            }
        }
    };
    


    initializeChannel.port2.onmessage = function(event){
        console.log("initializeChannel.port2.onmessage");
        console.log(event.data.message);
        sabNumNps = event.data.sabNumNps;

        sabNumA = event.data.sabNumA;
        sabNumB = event.data.sabNumB;
        sabNumC = event.data.sabNumC;
        sabNumD = event.data.sabNumD;
        sabNumI = event.data.sabNumI;
        sabNumW = event.data.sabNumW;
        sabNumPos = event.data.sabNumPos;
        sabNumConnectome = event.data.sabNumConnectome;
        sabNumNeuronCircle = event.data.sabNumNeuronCircle;
        sabNumConfig = event.data.sabNumConfig;
        sabNumCom = event.data.sabNumCom;
        sabNumIsPlaying = event.data.sabNumIsPlaying;

        // PASS POINTER AND INPUT
        sabDistPrefs = event.data.sabDistPrefs;
        sabSpeakerBuf = event.data.sabSpeakerBuf;
        sabMicrophoneBuf = event.data.sabMicrophoneBuf;
        sabLedBuf = event.data.sabLedBuf;
        sabLedPosBuf = event.data.sabLedPosBuf;
        sabVisualInputBuf = event.data.sabVisualInputBuf;
        sabDistanceBuf = event.data.sabDistanceBuf;
        sabDistanceMinLimitBuf = event.data.sabDistanceMinLimitBuf;
        sabDistanceMaxLimitBuf = event.data.sabDistanceMaxLimitBuf;
        // PASS POINTER AND INPUT
        
        // PASS UI POINTERS
        periodicNeuronSpikingFlags = event.data.periodicNeuronSpikingFlags;
        console.log("periodicNeuronSpikingFlagsZZZ:", periodicNeuronSpikingFlags);
        // PASS UI POINTERS

        // START SIMULATION
        sabNeuronTypeBuf = event.data.sabNeuronTypeBuf;
        sabDelayNeuronBuf = event.data.sabDelayNeuronBuf;
        // START SIMULATION


        // OPENCV & SIMULATION
        sabVisPrefs = event.data.sabVisPrefs;
        sabNeuronContacts = event.data.sabNeuronContacts;
        sabMotorCommands = event.data.sabMotorCommands;
        console.log("jsonData");
        console.log(jsonData);

        sabNumA.set(jsonData[0]);
        sabNumB.set(jsonData[1]);
        sabNumC.set(jsonData[2]);
        sabNumD.set(jsonData[3]);
        sabNumI.set(jsonData[4]);
        sabNumW.set(jsonData[5]);
        // sabNumPos.set(jsonData[6]);
        sabNumPos.set(0);
        sabNumConnectome.set(jsonData[7]);
        sabNumConfig.fill(0);
        sabNumCom.fill(-1);
        sabNumNeuronCircle.fill(0);
        sabNumIsPlaying.fill(0);
        sabVisPrefs.set(jsonData[13]);
        sabNeuronContacts.set(jsonData[14]);
        // sabMotorCommands.set(jsonData[15]);
        sabNeuronTypeBuf.set(jsonData[16]);
        sabDelayNeuronBuf.set(jsonData[17]);
        sabDistPrefs.set(jsonData[18]);
        sabSpeakerBuf.set(jsonData[19]);
        sabMicrophoneBuf.set(jsonData[20]);
        sabLedBuf.set(jsonData[21]);
        sabLedPosBuf.set(jsonData[22]);
        sabDistanceBuf.set(jsonData[23]);
        sabDistanceMinLimitBuf.set(jsonData[24]);
        sabDistanceMaxLimitBuf.set(jsonData[25]);
        console.log("sabDistanceMinLimitBuf _ sabDistanceMaxLimitBuf: ", sabDistanceMinLimitBuf, sabDistanceMaxLimitBuf);

        // sabNeuronTypeBuf, sabDelayNeuronBuf, sabDistPrefs, sabSpeakerBuf, sabMicrophoneBuf, sabLedBuf, sabLedPosBuf, sabVisualInputBuf, sabDistanceBuf, sabDistanceMinLimitBuf, sabDistanceMaxLimitBuf        
        // pVisPrefs, pNeuronContacts, pMotorCommands,
        sabCanvasBuffer = event.data.allocatedCanvasbuffer;
        //remove me
        // sabNumConfig[0] = 9;
        window.setCanvasBuffer(event.data.allocatedCanvasbuffer, event.data.sabNumPos,event.data.sabNumNeuronCircle, event.data.sabNumNps);

        // window.setCanvasBuffer(event.data.allocatedCanvasbuffer, event.data.sabNumPos,event.data.sabNumNeuronCircle, event.data.sabNumNps, event.data.sabVisPrefs, event.data.sabNeuronContacts, event.data.);
        izhikevichWorker.postMessage({
            message:'RUN_WORKER',
        });

        // window.setCanvasBuffer(event.data.allocatedCanvasbuffer, sabNumPos,sabNumNeuronCircle);

    };

    simulationWorkerChannel.port2.onmessage = function(event){
        if (event.data.message == 'INITIALIZED_WORKER'){
            // izhikevichWorker.postMessage({
            //     message:'CONNECT_SIMULATION',
            // });
            runSimulation(event.data);
            event.data.sabStateBuffer[STATE.BATTERY_STATUS] = 70;
            console.log("passSharedArrayBufferrrr", );
            console.log(event.data.sabStateBuffer);
            window.passSab(event.data.sabStateBuffer, event.data.sabVisPrefs, );
            // window.passSab(new Int32Array(30), new Int32Array(30) );
            // sabStateBuffer = allocatedBuffer.sabStateBuffer;
            // sabCameraDrawBuffer = allocatedBuffer.sabCameraDrawBuffer;
            // sabVisPrefs = allocatedBuffer.sabVisPrefs;
            // sabVisPrefVals = allocatedBuffer.sabVisPrefVals;
        
        }
        // console.log("event main thread");
        // console.log(event);
        // window.neuronTrigger(sabNumNeuronCircle);
    
    }
}
function setIsPlaying(flag){
    sabNumIsPlaying[0]=flag;
}


function runSimulation(allocatedBuffer){
    console.log("RUN SIMULATION");
    sabStateBuffer = allocatedBuffer.sabStateBuffer;
    sabCameraDrawBuffer = allocatedBuffer.sabCameraDrawBuffer;
    sabVisPrefs = allocatedBuffer.sabVisPrefs;
    sabVisPrefVals = allocatedBuffer.sabVisPrefVals;
    console.log(sabVisPrefs);
    
    // ptrStateBuffer | WS, PreProcess CV, Neuron Simulation, UI
    // ptrMotorCommands | WS, Neuron Simulation
    // ptrCameraDrawBuffer | WS, UI, PreProcess CV, 
    // ptrVisPrefs | UI, PreProcessCV, 
    // ptrVisPrefVals | UI, PreProcessCV
    // Vis Prefs&Vals create connectomeCV like connectome but for 

    // ptrMotorCommands: ptrMotorCommands,
    // ptrVisPrefs: ptrVisPrefs,
    // ptrVisPrefVals: ptrVisPrefVals,

    // canvasLeftElement = document.getElementById("canvasLeft");
    // ctxLeft = canvasLeftElement.getContext('2d', { willReadFrequently: true });
    imgCameraLeft = document.getElementById("imageLeft");
    canvasLeftElement = document.getElementById("canvasLeft");
    canvasLeftElement.style.visibility = 'hidden';
    ctxLeft = canvasLeftElement.getContext('2d', { willReadFrequently: true });

    canvasLeftElement.style.top = Math.abs(canvasLeftElement.style.top);
    canvasLeftElement.style.right = Math.abs(canvasLeftElement.style.right);
    // alert(canvasLeftElement.style.top);

    imgCamera = document.getElementById("image");
    canvasRightElement = document.getElementById("canvasRight");
    canvasRightElement.style.visibility = 'visible';
    // canvasRightElement.style.top = Math.abs(canvasRightElement.style.top);
    // canvasRightElement.style.right = Math.abs(canvasRightElement.style.right);
    // canvasRightElement.style.top = Math.abs(parseInt(canvasRightElement.style.top.replace("px", ""))) + "px";
    // canvasRightElement.style.right = Math.abs(parseInt(canvasRightElement.style.right.replace("px", ""))) + "px";

    ctxRight = canvasRightElement.getContext('2d', { willReadFrequently: true });
    // /* IMPORTANT
    recognitionWorker = new Worker('build/web/recognition.worker.js');
    recognitionWorker.postMessage({
        message:'MOCK',
    });

    // */
    // ctx = canvas.getContext('2d');
    // alert(offscreenCanvasElement);
    // offscreenCanvas = offscreenCanvasElement.transferControlToOffscreen();
    // ctx = offscreenCanvas.getContext('2d');
    // imgData = ctx.createImageData(frameWidth, frameHeight);
    // for (let i = 0; i < imgData.data.length; i += 4) {
    //     imgData.data[i+0] = 0;
    //     imgData.data[i+1] = 255;
    //     imgData.data[i+2] = 0;
    //     imgData.data[i+3] = 255;
    // }                                    

    // console.log("Websocket worker", offscreenCanvas);


    // FETCH WEBSOCKET IMAGE FRAME
    if (!isEngineWarmed){
        stopThreadProcess();
        setTimeout(()=>{
            try{
                izhikevichWorker.terminate();
                preprocessWorker.terminate();
                
                // websocketWorker.terminate();
                // websocketcommandWorker.terminate();
            }catch(err){

            }
            isEngineWarmed = true;
    
        }, 700);
    }else{
        
        isPlaying = true;
        setTimeout(()=>{
            izhikevichWorker.postMessage({
                message:'CONNECT_SIMULATION',
            });
        }, 2000);

        preprocessWorker = new Worker('build/web/preprocess.worker.js');
        preprocessWorker.postMessage({
            "message": "INITIALIZE",
            "sabStateBuffer":sabStateBuffer,
            "sabCameraDrawBuffer":sabCameraDrawBuffer,
            "sabVisPrefs":sabVisPrefs,
            "sabVisPrefVals":sabVisPrefVals,
            "sabVisualInputBuf":sabVisualInputBuf,
            "sabNeuronContacts":sabNeuronContacts,
            "neuronSize":neuronSize,
            // "sabPreprocessColorDetection":sabPreprocessColorDetection,
        });
        preprocessWorker.onmessage = function( evt ){
            switch( evt.data.message ){
                case "INITIALIZED_WASM_PREPROCESS":
                    console.log("INITIALIZED_WASM_PREPROCESS");
                    console.log(Date());
                    sabPreprocessCameraBuffer = evt.data.sabPreprocessCameraBuffer;
                    sabPreprocessColorDetection = evt.data.sabPreprocessColorDetection;
                    sabPreprocessColorDetection.fill(0);
                    // /* IMPORTANT
    
                    preprocessWorker.postMessage({
                        "message": "START_PREPROCESS",
                    });
    
                    const channels = 4;
                    sabAiPreprocessCameraBuffer = new Uint8Array( new SharedArrayBuffer(320*320 * channels) );
                    sabAiBoundingBox = new Float32Array( new SharedArrayBuffer( 7 * Float32Array.BYTES_PER_ELEMENT) );
                                
                    recognitionWorker.onmessage = function( evt ){
                        switch( evt.data.message ){
                            case "MOCKED":
                                recognitionWorker.postMessage({
                                    "message": "INITIALIZE",
                                    "neuronSize": neuronSize,
                                    "sabStateBuffer": sabStateBuffer,
                                    "sabVisPrefs": sabVisPrefs,
                                    "sabVisualInputBuf": sabVisualInputBuf,
                                    "sabAiPreprocessCameraBuffer": sabAiPreprocessCameraBuffer,
                                    "sabAiBoundingBox": sabAiBoundingBox,
                                    "sabPreprocessObjectDetection":sabPreprocessObjectDetection,
                                });            
                            break;
                            case "INITIALIZED":
                                console.log("RECOGNITION INITIALIZED");
                                sabPreprocessObjectDetection = evt.data.sabPreprocessObjectDetection;
                                sabPreprocessObjectDetection.fill(0);

                                setTimeout(() => {
                                    recognitionWorker.postMessage({
                                        "message": "START_RECOGNITION",
                                    });
    
                                }, 7000);
            
                            break;
                            case "INITIALIZED":
                            break;
    
                        }
                    }
                
                    window.passUiPointers(periodicNeuronSpikingFlags, sabPreprocessColorDetection, sabPreprocessObjectDetection);
                    //  */
                
                break;
            }
        }
    
    

        websocketWorker = new Worker('build/web/websocket.worker.js');
        console.log("INSTANTIATE WEBSOCKET WORKER");
        websocketWorker.postMessage({
            "message": "INITIALIZE",
            "sabStateBuffer":sabStateBuffer,
            "sabCameraDrawBuffer":sabCameraDrawBuffer,
            // "offscreenCanvas": offscreenCanvas,
        // },[offscreenCanvas]);
        });

        websocketWorker.onmessage = function( evt ){
            switch( evt.data.message ){
                case "INITIALIZED":
                    setTimeout(()=>{
                        websocketWorker.postMessage({
                            "message": "START",
                        });
                    },2000);
                break;
                case "STOP_WEBSOCKET":
                    websocketWorker.terminate();                   
                break;

            }
        }    



        websocketcommandWorker = new Worker('build/web/websocketcommand.worker.js');
        websocketcommandWorker.postMessage({
            "message": "INITIALIZE",
            "sabStateBuffer":sabStateBuffer,
            "sabDistanceBuf":sabDistanceBuf,
            "sabMotorCommand":sabMotorCommands,
            // "offscreenCanvas": offscreenCanvas,
        // },[offscreenCanvas]);
        });
    
        
        websocketcommandWorker.onmessage = function( evt ){
            switch( evt.data.message ){
                case "INITIALIZED_WEB_SOCKET":
                    // const sabStateCommand = evt.data.sabStateCommand;
                    // setInterval(()=>{
                    //     console.log("TIMEOUT!!!");
                    //     Atomics.notify(sabStateBuffer, STATE.COMMAND_MOTORS, Math.random() * 20 + 1);
                    // }, 7000);
        
                    setTimeout(()=>{
                        websocketcommandWorker.postMessage({
                            "message": "START",
                        });
                    },2000);
                break;
                case "STOP_WEBSOCKET":
                    console.log("websocketcommandWorker", "STOP_WEBSOCKET");
                    websocketcommandWorker.terminate();                   
                break;
            }
        };
    
  
        /* IMPORTANT
        recognitionWorker = new Worker('build/web/recognition.worker.js');
        */
        /* IMPORTANT
        const channels = 4;
        sabAiPreprocessCameraBuffer = new Uint8Array( new SharedArrayBuffer(320*320 * channels) );
        sabAiBoundingBox = new Float32Array( new SharedArrayBuffer( 4 * Float32Array.BYTES_PER_ELEMENT) );
        preprocessWorker.postMessage({
            "message": "START_PREPROCESS",
        });
        
        recognitionWorker.postMessage({
            "message": "INITIALIZE",
            "sabStateBuffer": sabStateBuffer,
            "sabAiPreprocessCameraBuffer": sabAiPreprocessCameraBuffer,
            "sabAiBoundingBox": sabAiBoundingBox,
        });
        recognitionWorker.onmessage = function( evt ){
            switch( evt.data.message ){
                case "INITIALIZED":
                    console.log("RECOGNITION INITIALIZED");
                    recognitionWorker.postMessage({
                        "message": "START_RECOGNITION",
                    });
                break;
            }
        }
            */
    }


    // send pointer into UI Thread
    // passUIPointers(ptrVisPrefs, ptrVisPrefVals);

}
// function setIzhikevichParameters(aBuf,bBuf,cBuf,dBuf,iBuf,wBuf,positionsBuf,connectomeBuf, level, neuronSize,envelopeSize,bufferSize,isPlaying){
function setIzhikevichParameters(jsonRawData){
    let jsonData = JSON.parse(jsonRawData);
    sabNumA.set(jsonData[0]);
    sabNumB.set(jsonData[1]);
    sabNumC.set(jsonData[2]);
    sabNumD.set(jsonData[3]);
    sabNumI.set(jsonData[4]);
    sabNumW.set(jsonData[5]);
    sabNumPos.set(jsonData[6]);
    sabNumConnectome.set(jsonData[7]);
    // for (let neuronIndex = 0; neuronIndex<neuronSize; neuronIndex++){
    //     sabNumA[neuronIndex] = (jsonData[0][neuronIndex]);
    //     sabNumB[neuronIndex] = (jsonData[1][neuronIndex]);
    //     sabNumC[neuronIndex] = (jsonData[2][neuronIndex]);
    //     sabNumD[neuronIndex] = (jsonData[3][neuronIndex]);
    //     sabNumI[neuronIndex] = (jsonData[4][neuronIndex]);
    //     sabNumW[neuronIndex] = (jsonData[5][neuronIndex]); 
    // }
    sabNumCom[0] = 1;
    // console.log("jsonData : ", sabNumCom, jsonData);
}

function stopThreadProcess(isStop){
    console.log("isEngineWarmed: ", isEngineWarmed);
    if (isEngineWarmed) {
        isPlaying = false;
        // alert(isEngineWarmed);
        sabStateBuffer[STATE.WEB_SOCKET] = -100;
        // sabStateBuffer[STATE.COMMAND_MOTORS] = 1;
        sabStateBuffer[STATE.CAMERA_CONTENT_STOP] = 1;
        Atomics.notify(sabStateBuffer, STATE.COMMAND_MOTORS, 1);
        ctxRight.clearRect(0, 0, 160, 120);
        canvasRightElement.style.visibility = 'hidden';
        
        // canvasLeftElement.style.top = -1 * Math.abs(parseInt(canvasLeftElement.style.top.replace("px", ""))) + "px";
        // canvasLeftElement.style.right = -1 * Math.abs(parseInt(canvasLeftElement.style.right.replace("px", ""))) + "px";
        
        sabPreprocessObjectDetection = undefined;
        sabPreprocessColorDetection = undefined;
        prevObjectIdxDetected = -1;
        prevColorDetected = -1;
        sleep(5000).then(() => {
            try {
                websocketcommandWorker.terminate()
            } catch (err) {

            }
            try {
                websocketWorker.terminate()
            } catch (err) {

            }

            try{
                preprocessWorker.terminate();
            }catch(ex){
            }
        
            try{
                recognitionWorker.terminate();
            }catch(ex){
            }
        
        });

    }
    // canvasRightElement.style.top = -1 * Math.abs(parseInt(canvasRightElement.style.top.replace("px", ""))) + "px";
    // canvasRightElement.style.right = -1 * Math.abs(parseInt(canvasRightElement.style.right.replace("px", ""))) + "px";

    sabNumConfig[1]=1;
    izhikevichWorker.postMessage({
        message: 'STOP_THREAD_PROCESS',
    });


}

function changeSelectedIdx(selectedIdx){
    if (selectedIdx!=-1){
        sabNumConfig[0] = selectedIdx;
        try{
            izhikevichWorker.postMessage({
                message: 'CHANGE_SELECTED_IDX',
                selectedIdx: selectedIdx,
            });
        }catch(err){
            console.log("err");
            console.log(err);
        }
    }
}

// window.canvasDraw(canvasBuffer);
let prevObjectIdxDetected = -1;
let prevColorDetected = -1;
const circularAngle = 2 * Math.PI;
function repaint(timestamp){
    try{
        // let image = document.getElementById('image');
        if (sabCameraDrawBuffer !== undefined){   
            // console.log("sabCameraDrawBuffer");
            // console.log(sabCameraDrawBuffer);
            const isFrameComplete = sabStateBuffer[STATE.CAMERA_CONTENT_COMPLETE];
            // console.log("COMPLETE : ", isFrameComplete);
            // only if there is a frame
            // if (isFrameComplete != lastFrameIdx || 1==1) {
            if (isFrameComplete != lastFrameIdx) {
                lastFrameIdx = isFrameComplete;
                const len = sabStateBuffer[STATE.CAMERA_CONTENT_LENGTH];
                const cameraContent = sabCameraDrawBuffer.slice(0,len);
                // const cameraContent = sabCameraDrawBuffer.subarray(0,len);
                // send to Flutter is not working because it will flicker

                // console.log("sabCanvasBuffer : ", sabCanvasBuffer);
                // window.streamImageFrame(cameraContent);

                // /* !!! IMPORTANT
                imgFrame = URL.createObjectURL(new Blob([cameraContent], {type: 'image/jpeg'})) 
                // // let frame = URL.createObjectURL(new Blob([cameraContent], {type: "video/x-motion-jpeg"})) 
                imgCamera.src = imgFrame;
                // */
                /*
                    // imgCamera.src = "http://127.0.0.1:5500/assets/bg/Cavendish_Banana_DS.jpg";
                    // imgCamera.src = "http://127.0.0.1:5500/assets/bg/greenbg.jpeg";
                    imgCamera.src = "http://127.0.0.1:5500/assets/bg/ObjBlackRedBg.jpg";
                    // imgCamera.src = "http://127.0.0.1:5500/assets/bg/person.jpg";
                    // imgCamera.src = "http://127.0.0.1:5500/assets/bg/banana.jpeg";
                    // imgCamera.src = "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9b/Cavendish_Banana_DS.jpg/440px-Cavendish_Banana_DS.jpg";
                */
                imgCamera.onload = function(){
                    // ctxLeft.drawImage(imgCamera, 0, 0, frameWidth, frameHeight);
                    ctxRight.drawImage(imgCamera, 0, 0, frameWidth/2, frameHeight/2);
                    // ctxRight.strokeStyle = 'blue';

                    // ctxRight.drawImage(imgPerson, sabAiBoundingBox[1] + sabAiBoundingBox[4]/2, sabAiBoundingBox[0], sabAiBoundingBox[4]/2, sabAiBoundingBox[5]);
                    if (sabAiBoundingBox !== undefined) {
                        // ctxRight.drawImage(imgPerson, sabAiBoundingBox[1] + sabAiBoundingBox[4]/2-16, sabAiBoundingBox[0], 16, 16);
                        // ctxRight.drawImage(imgPerson, sabAiBoundingBox[1] + sabAiBoundingBox[4]/2-16, sabAiBoundingBox[0], 16, 16);
                        ctxRight.font = "15px Noto Emoji";
                        ctxRight.fillStyle = 'white';
                        if (arrLookupEmoji[sabAiBoundingBox[6]-7] !== undefined) {
                            ctxRight.fillText(arrLookupEmoji[sabAiBoundingBox[6]-7], sabAiBoundingBox[1] + sabAiBoundingBox[4]/2-16 , sabAiBoundingBox[0]+ 16);
                            ctxRight.stroke();
                            // ctxRight.beginPath();
                            // ctxRight.arc(sabAiBoundingBox[1] + sabAiBoundingBox[4]/2-16 , sabAiBoundingBox[0]+ 16, 7, 0, circularAngle); // (x, y, radius, start angle, end angle)
                            // ctxRight.fill();

                        }
                    }

                    if (sabPreprocessColorDetection !== undefined) {
                        if (sabPreprocessColorDetection[2] > 8) {
                            // ctxRight.fillStyle = 'blue';
                            // ctxRight.fillStyle = '#000000';
                            ctxRight.fillStyle = '#1996FC';

                            ctxRight.beginPath();
                            ctxRight.arc(sabPreprocessColorDetection[0] + 10, sabPreprocessColorDetection[1], 7, 0, circularAngle); // (x, y, radius, start angle, end angle)
                            ctxRight.fill();
                        }
                        if (sabPreprocessColorDetection[5] > 8) {
                            // console.log("sabPreprocessColorDetection !! defined", sabPreprocessColorDetection[3],  sabPreprocessColorDetection[4], sabPreprocessColorDetection[8]);

                            // ctxRight.fillStyle = 'green';
                            // ctxRight.fillStyle = '#FFffFF';
                            ctxRight.fillStyle = '#18A953';
                            ctxRight.beginPath();
                            ctxRight.arc(sabPreprocessColorDetection[3] + 10, sabPreprocessColorDetection[4], 7, 0, circularAngle); // (x, y, radius, start angle, end angle)
                            ctxRight.fill();
                            
                        }
                        if (sabPreprocessColorDetection[8] > 8) {
                            ctxRight.fillStyle = 'red';
                            // ctxRight.fillStyle = '#ee00ee';
                            ctxRight.beginPath();
                            ctxRight.arc(sabPreprocessColorDetection[6] + 10, sabPreprocessColorDetection[7], 7, 0, circularAngle); // (x, y, radius, start angle, end angle)
                            ctxRight.fill();                        
                        }
                    }

                    if (sabStateBuffer[STATE.PREPROCESS_IMAGE] == 0 && sabPreprocessCameraBuffer !== undefined){                       
                        // console.log("color detection", sabStateBuffer[STATE.PREPROCESS_IMAGE]);
                        // sabStateBuffer[STATE.PREPROCESS_IMAGE_PROCESSING] = 1;
                        imgData = ctxRight.getImageData(0, 0, frameWidth/2, frameHeight/2);

                        sabPreprocessCameraBuffer.set( imgData.data );

                        sabStateBuffer[STATE.PREPROCESS_IMAGE_LENGTH] = imgData.data.length;
                        // sabCameraDrawBuffer.set(imgData);
                        // console.log("color detection notify");
                        Atomics.notify(sabStateBuffer, STATE.PREPROCESS_IMAGE,1);
                    }

                    //send imgData to wasm 
                    // /* !!! IMPORTANT
                        URL.revokeObjectURL(imgFrame)
                    // */
                }
                // tensorflow resize gave different result https://stackoverflow.com/questions/47841840/tensorflow-resizebilinear-gives-different-results-than-cvresize

                // imgCameraLeft.src = "http://127.0.0.1:5500/assets/bg/banana.jpeg";
                // /* !!! IMPORTANT
                imgLeftFrame = URL.createObjectURL(new Blob([cameraContent], {type: 'image/jpeg'}));
                imgCameraLeft.src = imgLeftFrame;
                // */
                // /*
                // imgCameraLeft.src = "http://127.0.0.1:5500/assets/bg/person.jpg";
                // imgCameraLeft.src = "http://127.0.0.1:5500/assets/bg/banana.jpeg";
                // imgCameraLeft.src = "http://127.0.0.1:5500/assets/bg/ObjBlackRedBg.jpg";

                // imgCameraLeft.src = "http://127.0.0.1:5500/assets/bg/greenbg.jpeg";;
                // sabVisualInputBuf[12 * 22 + 2] = 50;
                // sabVisualInputBuf[22* 12 + 3] = 50;
                // */
                imgCameraLeft.onload = function(){
                    ctxLeft.drawImage(imgCameraLeft, 0, 0, 320, 320);
                    if (sabStateBuffer[STATE.AIPROCESS_IMAGE_PROCESSING] == 0 && sabAiPreprocessCameraBuffer !== undefined){
                        // console.log("AIPROCESS STARTZZZ");
                        // Atomics.store(sabStateBuffer, STATE.AIPROCESS_IMAGE_PROCESSING, 1);
                        const imgData = ctxLeft.getImageData(0, 0, 320, 320);
                        sabAiPreprocessCameraBuffer.set( imgData.data );

                        sabStateBuffer[STATE.AIPROCESS_IMAGE_LENGTH] = imgData.data.length;
                        Atomics.notify(sabStateBuffer, STATE.AIPROCESS_IMAGE_LENGTH,1);                        
                        Atomics.notify(sabStateBuffer, STATE.RECOGNIZE_IMAGE,1);
                    }
                    // /* !!! IMPORTANT
                    URL.revokeObjectURL(imgLeftFrame)
                    // */
                };

                // console.log("periodicNeuronSpikingFlags");
                // console.log(periodicNeuronSpikingFlags);
                window.updateRobotStatus();
                // Fill this
                if (sabPreprocessColorDetection !== undefined && sabPreprocessObjectDetection !== undefined) {
                    let detection = 0;
                    if (prevObjectIdxDetected != sabPreprocessObjectDetection[0] ) {
                        prevObjectIdxDetected = sabPreprocessObjectDetection[0];
                        detection++;
                    }
                    let sum = sabPreprocessColorDetection.reduce((a, b)=>{
                        return a+b;
                    });
                    if (prevColorDetected != sum) {
                        prevColorDetected = sum;
                        detection++;
                    }

                    if (detection > 0) {
                        window.passImageDetection(sabPreprocessColorDetection, sabPreprocessObjectDetection, sabAiBoundingBox);
                    }
                }
    
                // imgData.data.set(sabCameraDrawBuffer);
                // ctx.putImageData(imgData,10,10);
                
                // image.src = sabCameraDrawBuffer;
            }
        }

        // console.log(sabNumNps);
        // if (sabCanvasBuffer!== undefined){
        //     console.log(sabCanvasBuffer[sabNumPos[0]]);
        // }
        // window.canvasDraw();
    }catch(exc){
      // window.callbackErrorLog( ["error_repaint", "Repaint Audio Error"] );
      console.log("exc");
      console.log(exc);
    }
    window.requestAnimationFrame(repaint);    

}  
window.requestAnimationFrame(repaint);


// function sendBufferReferences(buf){
//     // alert(213);
//     // canvasBuffer = [buf];
//     // console.log(ab, typeof ab);
// }


setTimeout(()=>{
    initializeModels(`[
        [0.02], [0.18], [-65], [2], [5.0], [2.0],  
        [0.0], [0.0],  
        1, 1, 200, 2000,
        1, [-1], [0], [0],
        [0], [0], [0], [0], [0],
        [0], [0], [0], [0], [0],[0]
    ]`);    
}, 2000);

//jsonEncode([aBufView,bBufView,cBufView,dBufView,iBufView,wBufView,
//positionsBufView, connectomeBufView,
//level, neuronSize,envelopeSize,bufferSize,1, visPrefsBufView, neuronContactsBufView, motorCommandBufView]) ]
//jsonEncode([aBufView,bBufView,cBufView,dBufView,iBufView,wBufView,
//positionsBufView, connectomeBufView,
//level, neuronSize,envelopeSize,bufferSize,1, visPrefsBufView, neuronContactsBufView, motorCommandBufView])

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

