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
let sabConfig;

let sabNumA;
let sabNumB;
let sabNumC;
let sabNumD;
let sabNumI;
let sabNumW;
let sabNumPos;
let sabNumConnectome;
let sabNumNeuronCircle;

let sabNumConfig;
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

    sabConfig = new SharedArrayBuffer( 10 * Uint32Array.BYTES_PER_ELEMENT );
    sabCom = new SharedArrayBuffer( 1 * Int16Array.BYTES_PER_ELEMENT );
    sabIsPlaying = new SharedArrayBuffer( 1 * Int16Array.BYTES_PER_ELEMENT );

    sabNumCom = new Int16Array(sabCom);
    sabNumConfig = new Uint32Array(sabConfig);
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
        console.log(event.data.allocatedCanvasbuffer);
        window.setCanvasBuffer(event.data.allocatedCanvasbuffer, event.data.sabNumPos,event.data.sabNumNeuronCircle, event.data.sabNumNps);
        izhikevichWorker.postMessage({
            message:'RUN_WORKER',
        });

        // window.setCanvasBuffer(event.data.allocatedCanvasbuffer, sabNumPos,sabNumNeuronCircle);

    };

    simulationWorkerChannel.port2.onmessage = function(event){
        if (event.data.message == 'INITIALIZED_WORKER'){
            izhikevichWorker.postMessage({
                message:'CONNECT_SIMULATION',
            });
        
        }
        // console.log("event main thread");
        // console.log(event);
        // window.neuronTrigger(sabNumNeuronCircle);
    
    }
}
function setIsPlaying(flag){
    sabNumIsPlaying[0]=flag;
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
        sabNumConfig[0]=selectedIdx;
    }
}

// window.canvasDraw(canvasBuffer);
function repaint(timestamp){
    try{
        // console.log(sabNumNps);
        window.canvasDraw();
    }catch(exc){
      // window.callbackErrorLog( ["error_repaint", "Repaint Audio Error"] );
    //   console.log("exc");
    //   console.log(exc);
    }

    window.requestAnimationFrame(repaint);    
}  
window.requestAnimationFrame(repaint);


// function sendBufferReferences(buf){
//     // alert(213);
//     // canvasBuffer = [buf];
//     // console.log(ab, typeof ab);
// }