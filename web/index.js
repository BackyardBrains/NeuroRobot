// WebSocket
const StateLength = 20;
var websocketWorker;
var preprocessWorker;
var websocketcommandWorker;

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
// PREPROCESS
var sabPreprocessCameraBuffer;
let sabCanvasBuffer;

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


// WEB SOCKET 
const frameWidth = 320;
const frameHeight = 240;
let offscreenCanvas;
let ctxLeft;
let imgData;
let imgCamera;

let canvasLeftElement;
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
// let sabCanvas=[];
// let canvasBuffers=[];
function initializeModels(jsonRawData){
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
        websocketcommandWorker.terminate();
    }catch(ex){
    }

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
        // OPENCV & SIMULATION
        sabVisPrefs = event.data.sabVisPrefs;
        sabNeuronContacts = event.data.sabNeuronContacts;
        sabMotorCommands = event.data.sabMotorCommands;


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
        console.log(jsonData);
        console.log(sabVisPrefs);
        sabVisPrefs.set(jsonData[13]);
        sabNeuronContacts.set(jsonData[14]);
        sabMotorCommands.set(jsonData[15]);
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

    canvasLeftElement = document.getElementById("canvasLeft");
    imgCamera = document.getElementById("image");
    ctxLeft = canvasLeftElement.getContext('2d', { willReadFrequently: true });

    canvasRightElement = document.getElementById("canvasRight");
    ctxRight = canvasRightElement.getContext('2d', { willReadFrequently: true });

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

    preprocessWorker = new Worker('build/web/preprocess.worker.js');
    preprocessWorker.postMessage({
        "message": "INITIALIZE",
        "sabStateBuffer":sabStateBuffer,
        "sabCameraDrawBuffer":sabCameraDrawBuffer,
        "sabVisPrefs":sabVisPrefs,
        "sabVisPrefVals":sabVisPrefVals,
        "sabNeuronContacts":sabNeuronContacts,
        "neuronSize":neuronSize,

    });
    preprocessWorker.onmessage = function( evt ){
        switch( evt.data.message ){
            case "INITIALIZED_WASM_PREPROCESS":
                sabPreprocessCameraBuffer = evt.data.sabPreprocessCameraBuffer;
                preprocessWorker.postMessage({
                    "message": "START_PREPROCESS",
                });
            break;
        }
    }

    websocketWorker = new Worker('build/web/websocket.worker.js');
    websocketWorker.postMessage({
        "message": "INITIALIZE",
        "sabStateBuffer":sabStateBuffer,
        "sabCameraDrawBuffer":sabCameraDrawBuffer,
        // "offscreenCanvas": offscreenCanvas,
    // },[offscreenCanvas]);
    });
    websocketcommandWorker = new Worker('build/web/websocketcommand.worker.js');
    websocketcommandWorker.postMessage({
        "message": "INITIALIZE",
        "sabStateBuffer":sabStateBuffer,
        "sabMotorCommand":sabMotorCommands,
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
        }
    }

    izhikevichWorker.postMessage({
        message:'CONNECT_SIMULATION',
    });

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
    sabNumConfig[1]=1;
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
function repaint(timestamp){
    try{
        // let image = document.getElementById('image');
        if (sabCameraDrawBuffer !== undefined){
            // console.log("sabCameraDrawBuffer");
            // console.log(sabCameraDrawBuffer);
            const isFrameComplete = sabStateBuffer[STATE.CAMERA_CONTENT_COMPLETE];
            // console.log("COMPLETE : ", isFrameComplete);
            // only if there is a frame
            if (isFrameComplete != lastFrameIdx) {
                lastFrameIdx = isFrameComplete;
                const len = sabStateBuffer[STATE.CAMERA_CONTENT_LENGTH];
                const cameraContent = sabCameraDrawBuffer.slice(0,len);
                // const cameraContent = sabCameraDrawBuffer.subarray(0,len);
                // console.log(len, cameraContent);
                // send to Flutter

                // console.log("sabCanvasBuffer : ", sabCanvasBuffer);
                // window.streamImageFrame(cameraContent);

                imgFrame = URL.createObjectURL(new Blob([cameraContent], {type: 'image/jpeg'})) 
                // // let frame = URL.createObjectURL(new Blob([cameraContent], {type: "video/x-motion-jpeg"})) 
                imgCamera.src = imgFrame;
                imgCamera.onload = function(){
                    ctxLeft.drawImage(imgCamera, 0, 0, frameWidth, frameHeight);
                    ctxRight.drawImage(imgCamera, 0, 0, frameWidth, frameHeight);
                    
                    if (sabStateBuffer[STATE.PREPROCESS_IMAGE_PROCESSING] == 0 && sabPreprocessCameraBuffer !== undefined){
                        sabStateBuffer[STATE.PREPROCESS_IMAGE_PROCESSING] = 1;
                        imgData = ctxLeft.getImageData(0, 0, frameWidth, frameHeight);

                        // sabPreprocessCameraBuffer.set(Array.from( imgData.data) );
                        sabPreprocessCameraBuffer.set( imgData.data );
                        // console.log("imgData", sabPreprocessCameraBuffer);
                        // console.log("sabPreprocessCameraBuffer", sabPreprocessCameraBuffer);
                        // console.log(imgData.data.subarray(0,30), sabPreprocessCameraBuffer.subarray(0,30));

                        sabStateBuffer[STATE.PREPROCESS_IMAGE_LENGTH] = imgData.data.length;
                        // sabCameraDrawBuffer.set(imgData);
                        Atomics.notify(sabStateBuffer, STATE.PREPROCESS_IMAGE,1);                        
                    }

                    //send imgData to wasm 
                    URL.revokeObjectURL(imgFrame)
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