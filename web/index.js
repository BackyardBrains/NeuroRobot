const COLOR_CHANNELS = 3;
let websocketMessageChannel;
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
var websocketproxycommandWorker;
var isEngineWarmed = false;
var isPlaying = false;
// var ptrStateBuffer;
// var ptrCameraDrawBuffer;
// var ptrVisPrefs;
// var ptrVisPrefVals;

var sabFirmwareVersion;
sabFirmwareVersion = new Uint8Array( new SharedArrayBuffer(3 * Uint8Array.BYTES_PER_ELEMENT) );

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
var sabPreprocessColorDetectionDraw;
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
var mapAreaSize;
var neuronKeys;
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
function initializeModels(jsonRawData){
    // imgPerson = document.getElementById("imagePerson");
    // imgPerson.src="http://127.0.0.1:5500/assets/icons/person.png";
    
    
    console.log("Initialize Models")
    tempJsonRawData = jsonRawData;
    try {
        izhikevichWorker.terminate();
    } catch(ex) {
    }
    try{
        preprocessWorker.terminate();
    }catch(ex){
    }

    try{
        websocketMessageChannel.port1.close();
    }catch(ex){
    }
    try{
        websocketMessageChannel.port2.close();
    }catch(ex){
    }

    try{
        websocketWorker.terminate();
    }catch(ex){
    }
    try{
        websocketcommandWorker.terminate();
    }catch(ex){
    }
    try{
        websocketproxycommandWorker.terminate();
    }catch(ex){
    }

    try{
        recognitionWorker.terminate();
    }catch(ex){
    }
        


    // console.log(jsonRawData);
    let jsonData = JSON.parse(jsonRawData);
    neuronSize = jsonData[9];

    sabCom = new SharedArrayBuffer( 1 * Int16Array.BYTES_PER_ELEMENT );
    sabIsPlaying = new SharedArrayBuffer( 1 * Int16Array.BYTES_PER_ELEMENT );
    
    sabPreprocessObjectDetection = new Float32Array(new SharedArrayBuffer( 7 * Float32Array.BYTES_PER_ELEMENT ));

    sabNumCom = new Int16Array(sabCom);
    // sabNumConfig = new Uint32Array(sabConfig);
    sabNumIsPlaying = new Int16Array(sabIsPlaying);
    
    simulationWorkerChannel = new MessageChannel();
    initializeChannel = new MessageChannel();

    izhikevichWorker = new Worker('build/web/workerSimulation.js');

    izhikevichWorker.onmessage=function(event){
        console.log(event.data);
        if (event.data.message == "INITIALIZE_WASM"){
            izhikevichWorker.postMessage({
                message:'INITIALIZE_WORKER',
                neuronSize:neuronSize,
                sabConfig:sabConfig,
                sabCom:sabCom,
                sabIsPlaying:sabIsPlaying,
                simulationWorkerChannelPort:simulationWorkerChannel.port1,
                initializeChannelPort:initializeChannel.port1,
            },[simulationWorkerChannel.port1, initializeChannel.port1]);
        }else
        if (event.data.message == "STOP_THREADS"){
            // if (isEngineWarmed) {
            // alert(123);
            try{
                recognitionWorker.terminate();
                preprocessWorker.terminate();
                izhikevichWorker.terminate();
            }catch(err){
                console.log("ERR: ", err);
            }
            // }
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
        // console.log("periodicNeuronSpikingFlagsZZZ:", periodicNeuronSpikingFlags);
        // PASS UI POINTERS

        // START SIMULATION
        sabNeuronTypeBuf = event.data.sabNeuronTypeBuf;
        sabDelayNeuronBuf = event.data.sabDelayNeuronBuf;
        // START SIMULATION


        // OPENCV & SIMULATION
        sabVisPrefs = event.data.sabVisPrefs;
        sabNeuronContacts = event.data.sabNeuronContacts;
        sabMotorCommands = event.data.sabMotorCommands;
        // console.log("jsonData");
        // console.log(jsonData);

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
        mapAreaSize=(jsonData[26]);
        neuronKeys=(jsonData[27]);
        console.log("sabDistanceMinLimitBuf _ sabDistanceMaxLimitBuf: ", sabDistanceMinLimitBuf, sabDistanceMaxLimitBuf);

        sabCanvasBuffer = event.data.allocatedCanvasbuffer;
        window.setCanvasBuffer(event.data.allocatedCanvasbuffer, event.data.sabNumPos,event.data.sabNumNeuronCircle, event.data.sabNumNps);

        izhikevichWorker.postMessage({
            message:'RUN_WORKER',
        });

    };

    simulationWorkerChannel.port2.onmessage = function(event){
        if (event.data.message == 'INITIALIZED_WORKER'){

            runSimulation(event.data);
            event.data.sabStateBuffer[STATE.BATTERY_STATUS] = 70;
            console.log("passSharedArrayBufferrrr", );
            console.log(event.data.sabStateBuffer);
            window.passSab(event.data.sabStateBuffer, event.data.sabVisPrefs, );
        }
    }
}
function setIsPlaying(flag){
    sabNumIsPlaying[0]=flag;
}


function runSimulation(allocatedBuffer){
    // console.log("RUN SIMULATION");
    sabStateBuffer = allocatedBuffer.sabStateBuffer;
    sabCameraDrawBuffer = allocatedBuffer.sabCameraDrawBuffer;
    sabVisPrefs = allocatedBuffer.sabVisPrefs;
    sabVisPrefVals = allocatedBuffer.sabVisPrefVals;
    // console.log(sabVisPrefs);
    
    imgCameraLeft = document.getElementById("imageLeft");
    canvasLeftElement = document.getElementById("canvasLeft");
    canvasLeftElement.style.visibility = 'hidden';
    ctxLeft = canvasLeftElement.getContext('2d', { willReadFrequently: true });

    canvasLeftElement.style.top = Math.abs(canvasLeftElement.style.top);
    canvasLeftElement.style.right = Math.abs(canvasLeftElement.style.right);

    imgCamera = document.getElementById("image");
    canvasRightElement = document.getElementById("canvasRight");
    canvasRightElement.style.visibility = 'visible';

    ctxRight = canvasRightElement.getContext('2d', { willReadFrequently: true });
    // /* IMPORTANT
    recognitionWorker = new Worker('build/web/recognition.worker.js');
    recognitionWorker.postMessage({
        message:'MOCK',
    });

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
            "mapAreaSize": mapAreaSize,
            "neuronKeys": neuronKeys,
            // "sabPreprocessColorDetection":sabPreprocessColorDetection,
        });
        preprocessWorker.onmessage = function( evt ){
            switch( evt.data.message ){
                case "INITIALIZED_WASM_PREPROCESS":
                    console.log("INITIALIZED_WASM_PREPROCESS");
                    console.log(Date());
                    sabPreprocessCameraBuffer = evt.data.sabPreprocessCameraBuffer;
                    sabPreprocessColorDetection = evt.data.sabPreprocessColorDetection;
                    sabPreprocessColorDetectionDraw = new Int16Array(new SharedArrayBuffer( 3 * COLOR_CHANNELS * Int16Array.BYTES_PER_ELEMENT ));
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
                                    "mapAreaSize": mapAreaSize,
                                    "neuronKeys": neuronKeys,
                                });            
                            break;
                            case "INITIALIZED":
                                console.log("RECOGNITION INITIALIZED");
                                sabPreprocessObjectDetection = evt.data.sabPreprocessObjectDetection;
                                sabPreprocessObjectDetection.fill(0);

                                // setTimeout(() => {
                                    recognitionWorker.postMessage({
                                        "message": "START_RECOGNITION",
                                    });
    
                                // }, 7000);
            
                            break;
                            case "INITIALIZED":
                            break;
    
                        }
                    }
                    sabPreprocessColorDetectionDraw.set(sabPreprocessColorDetection);
                    window.passUiPointers(periodicNeuronSpikingFlags, sabPreprocessColorDetectionDraw, sabPreprocessObjectDetection, sabFirmwareVersion);
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


        websocketMessageChannel = new MessageChannel();
        websocketcommandWorker = new Worker('build/web/websocketcommand.worker.js');
        websocketcommandWorker.postMessage({
            "message": "INITIALIZE",
            "sabStateBuffer":sabStateBuffer,
            "sabDistanceBuf":sabDistanceBuf,
            "sabMotorCommand":sabMotorCommands,
            "sabFirmwareVersion":sabFirmwareVersion,
            "websocketMessageChannelReceive": websocketMessageChannel.port2
            // "offscreenCanvas": offscreenCanvas,
        // },[offscreenCanvas]);
        }, [websocketMessageChannel.port2]);

        websocketproxycommandWorker = new Worker('build/web/websocketproxycommand.worker.js');
        websocketproxycommandWorker.postMessage({
            "message": "INITIALIZE",
            "sabStateBuffer":sabStateBuffer,
            "sabDistanceBuf":sabDistanceBuf,
            "sabMotorCommand":sabMotorCommands,
            "sabFirmwareVersion":sabFirmwareVersion,
            "websocketMessageChannelSend": websocketMessageChannel.port1
            // "offscreenCanvas": offscreenCanvas,
        // },[offscreenCanvas]);
        }, [websocketMessageChannel.port1]);
    
        
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
                        websocketproxycommandWorker.postMessage({
                            "message": "START_PROXY",
                        });

                    },2000);
                break;
                case "STOP_WEBSOCKET":
                    console.log("websocketcommandWorker", "STOP_WEBSOCKET");
                    try{
                        websocketMessageChannel.port1.close();
                    }catch(ex){
                    }
                    try{
                        websocketMessageChannel.port2.close();
                    }catch(ex){
                    }                
                    try{
                        websocketcommandWorker.terminate();                   
                        websocketproxycommandWorker.terminate();    
                    }catch(err) {
                        console.log(err);
                    }


                    try{
                        preprocessWorker.terminate();
                    }catch(ex){
                    }
                
                    try{
                        recognitionWorker.terminate();
                    }catch(ex){
                    }
        

                break;
            }
        };
    }
    // send pointer into UI Thread

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
        websocketcommandWorker.postMessage({
            "message": "CLOSE",
        });

        sabPreprocessObjectDetection = undefined;
        sabPreprocessColorDetection = undefined;
        prevObjectIdxDetected = -1;
        prevColorDetected = -1;
        // sleep(5000).then(() => {
        //     try{
        //         websocketMessageChannel.port1.close();
        //     }catch(ex){
        //     }
        //     try{
        //         websocketMessageChannel.port2.close();
        //     }catch(ex){
        //     }
        
        //     try {
        //         websocketcommandWorker.terminate()
        //     } catch (err) {

        //     }
        //     try {
        //         websocketproxycommandWorker.terminate();
        //     } catch (err) {

        //     }
        //     try {
        //         websocketWorker.terminate()
        //     } catch (err) {

        //     }

        //     try{
        //         preprocessWorker.terminate();
        //     }catch(ex){
        //     }
        
        //     try{
        //         recognitionWorker.terminate();
        //     }catch(ex){
        //     }
        // });
    }

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
        if (sabCameraDrawBuffer !== undefined){   
            const isFrameComplete = sabStateBuffer[STATE.CAMERA_CONTENT_COMPLETE];
            if (isFrameComplete != lastFrameIdx) {
                lastFrameIdx = isFrameComplete;
                const len = sabStateBuffer[STATE.CAMERA_CONTENT_LENGTH];
                const cameraContent = sabCameraDrawBuffer.slice(0,len);
                // const cameraContent = sabCameraDrawBuffer.subarray(0,len);
                // send to Flutter is not working because it will flicker

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
                    ctxRight.drawImage(imgCamera, 0, 0, frameWidth/2, frameHeight/2);

                    if (sabAiBoundingBox !== undefined) {
                        ctxRight.font = "15px Noto Emoji";
                        ctxRight.fillStyle = 'white';
                        if (arrLookupEmoji[sabAiBoundingBox[6]-7] !== undefined) {
                            ctxRight.fillText(arrLookupEmoji[sabAiBoundingBox[6]-7], sabAiBoundingBox[1] + sabAiBoundingBox[5]/2-16 , sabAiBoundingBox[0]+ 16);
                            // ctxRight.stroke();
                        }
                    }

                    if (sabPreprocessColorDetection !== undefined) {
                        if (sabPreprocessColorDetection[2] > 8) {
                            ctxRight.fillStyle = '#1996FC';

                            ctxRight.beginPath();
                            ctxRight.arc(sabPreprocessColorDetection[0] + 10, sabPreprocessColorDetection[1], 7, 0, circularAngle); // (x, y, radius, start angle, end angle)
                            ctxRight.fill();
                            ctxRight.closePath();
                            
                        }
                        if (sabPreprocessColorDetection[5] > 8) {
                            ctxRight.fillStyle = '#18A953';
                            ctxRight.beginPath();
                            ctxRight.arc(sabPreprocessColorDetection[3] + 10, sabPreprocessColorDetection[4], 7, 0, circularAngle); // (x, y, radius, start angle, end angle)
                            ctxRight.fill();
                            ctxRight.closePath();
                            
                        }
                        if (sabPreprocessColorDetection[8] > 8) {
                            ctxRight.fillStyle = 'red';
                            ctxRight.beginPath();
                            ctxRight.arc(sabPreprocessColorDetection[6] + 10, sabPreprocessColorDetection[7], 7, 0, circularAngle); // (x, y, radius, start angle, end angle)
                            ctxRight.fill();                        
                            ctxRight.closePath();
                        }
                    }

                    if (sabStateBuffer[STATE.PREPROCESS_IMAGE] == 0 && sabPreprocessCameraBuffer !== undefined){                       
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
                        if (sabPreprocessObjectDetection !== undefined && sabPreprocessObjectDetection !== null) {
                            window.passImageDetection(sabPreprocessColorDetection, sabPreprocessObjectDetection, sabAiBoundingBox);
                        }
                    }
                }
    
            }
        }

    }catch(exc){
      console.log("exc");
      console.log(exc);
    }
    window.requestAnimationFrame(repaint);    

}  
window.requestAnimationFrame(repaint);


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

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

