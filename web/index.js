var izhikevichWorker;
const neuronSize = 2;
const windowSize = 200*30;
let sabA = new SharedArrayBuffer( neuronSize * Float64Array.BYTES_PER_ELEMENT );
let sabB = new SharedArrayBuffer( neuronSize * Float64Array.BYTES_PER_ELEMENT );
let sabC = new SharedArrayBuffer( neuronSize * Int16Array.BYTES_PER_ELEMENT );
let sabD = new SharedArrayBuffer( neuronSize * Int16Array.BYTES_PER_ELEMENT );
let sabI = new SharedArrayBuffer( neuronSize * Float64Array.BYTES_PER_ELEMENT );
let sabW = new SharedArrayBuffer( neuronSize * Float64Array.BYTES_PER_ELEMENT );
let sabPos = new SharedArrayBuffer( neuronSize * Uint32Array.BYTES_PER_ELEMENT );
let sabConnectome = new SharedArrayBuffer( neuronSize * neuronSize * Float64Array.BYTES_PER_ELEMENT );
let sabCom = new SharedArrayBuffer( 1 * Int16Array.BYTES_PER_ELEMENT );
let sabNeuronCircle = new SharedArrayBuffer( neuronSize * Int16Array.BYTES_PER_ELEMENT );
let sabIsPlaying = new SharedArrayBuffer( 1 * Int16Array.BYTES_PER_ELEMENT );

let sabNumA = new Float64Array(sabA);
let sabNumB = new Float64Array(sabB);
let sabNumC = new Int16Array(sabC);
let sabNumD = new Int16Array(sabD);
let sabNumI = new Float64Array(sabI);
let sabNumW = new Float64Array(sabW);
let sabNumPos = new Uint32Array(sabPos);
let sabNumConnectome = new Float64Array(sabConnectome);
let sabNumCom = new Int16Array(sabCom);
let sabNumNeuronCircle = new Int16Array(sabNeuronCircle);
let sabNumIsPlaying = new Int16Array(sabIsPlaying);
let simulationWorkerChannel = new MessageChannel();

let sabCanvas=[];
let canvasBuffer=[];
function initializeModels(jsonRawData){
    try{
        izhikevichWorker.terminate();
    }catch(ex){
    }

    let jsonData = JSON.parse(jsonRawData);    
    izhikevichWorker = new Worker('build/web/workerSimulation.js');
    for (let i = 0;i<1;i++){
        let sab = new SharedArrayBuffer( windowSize * Float64Array.BYTES_PER_ELEMENT )        
        sabCanvas.push(sab);
        canvasBuffer.push(new Float64Array(sab));
    }
    canvasBuffer.push(sabNumPos)

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
   
    for (let neuronIndex = 0; neuronIndex<neuronSize; neuronIndex++){
        sabNumA[neuronIndex] = (jsonData[0][neuronIndex]);
        sabNumB[neuronIndex] = (jsonData[1][neuronIndex]);
        sabNumC[neuronIndex] = (jsonData[2][neuronIndex]);
        sabNumD[neuronIndex] = (jsonData[3][neuronIndex]);
        sabNumI[neuronIndex] = (jsonData[4][neuronIndex]);
        sabNumW[neuronIndex] = (jsonData[5][neuronIndex]); 
        sabNumConnectome[neuronIndex] = (jsonData[6][neuronIndex]); 
    }

    sabNumCom.fill(-1);
    sabNumNeuronCircle.fill(0);
    sabNumIsPlaying.fill(0);
    // canvasBuffer.push(sabNumNeuronCircle);
    
    izhikevichWorker.postMessage({
        message:'INITIALIZE_WORKER',
        neuronSize:neuronSize,
        sabA:sabA,
        sabB:sabB,
        sabC:sabC,
        sabD:sabD,
        sabI:sabI,
        sabW:sabW,
        sabPos:sabPos,
        sabConnectome:sabConnectome,
        sabCanvas:sabCanvas,
        sabCom:sabCom,
        sabNeuronCircle:sabNeuronCircle,
        sabIsPlaying:sabIsPlaying,
        simulationWorkerChannelPort:simulationWorkerChannel.port1,
    },[simulationWorkerChannel.port1]);
    simulationWorkerChannel.port2.onmessage = function(event){
        // console.log("event main thread");
        // console.log(event);
        window.neuronTrigger(sabNumNeuronCircle);
    
    }
}
function setIsPlaying(flag){
    sabNumIsPlaying[0]=flag;
}

// function setIzhikevichParameters(aBuf,bBuf,cBuf,dBuf,iBuf,wBuf,positionsBuf,connectomeBuf, level, neuronSize,envelopeSize,bufferSize,isPlaying){
function setIzhikevichParameters(jsonRawData){
    let jsonData = JSON.parse(jsonRawData);
    for (let neuronIndex = 0; neuronIndex<neuronSize; neuronIndex++){
        sabNumA[neuronIndex] = (jsonData[0][neuronIndex]);
        sabNumB[neuronIndex] = (jsonData[1][neuronIndex]);
        sabNumC[neuronIndex] = (jsonData[2][neuronIndex]);
        sabNumD[neuronIndex] = (jsonData[3][neuronIndex]);
        sabNumI[neuronIndex] = (jsonData[4][neuronIndex]);
        sabNumW[neuronIndex] = (jsonData[5][neuronIndex]); 
    }
    sabNumCom[0] = 1;
    console.log("jsonData : ", sabNumCom, jsonData);
}

// window.canvasDraw(canvasBuffer);
function repaint(timestamp){
    try{
        // console.log(canvasBuffer[1]);
        window.canvasDraw(canvasBuffer);
    }catch(exc){
      // window.callbackErrorLog( ["error_repaint", "Repaint Audio Error"] );
    //   console.log("exc");
    //   console.log(exc);
    }

    window.requestAnimationFrame(repaint);    
}  
window.requestAnimationFrame(repaint);
