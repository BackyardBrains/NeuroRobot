let neuronSize = 2;
let windowSize = 200 * 30;
let sabA;
let sabB;
let sabC;
let sabD;
let sabI;
let sabW;
let sabPos;
let sabCom;
let sabNeuronCircle;
let sabIsPlaying;

let sabNumA;
let sabNumB;
let sabNumC;
let sabNumD;
let sabNumI;
let sabNumW;
let sabNumPos;
let sabNumCom;
let sabNumNeuronCircle;
let sabNumIsPlaying;
let simulationWorkerChannelPort;


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
    if (eventFromMain.data.message === 'INITIALIZE_WORKER') {
        console.log("Initialize Worker")
        neuronSize = eventFromMain.data.neuronSize;
        sabA = eventFromMain.data.sabA;
        sabB = eventFromMain.data.sabB;
        sabC = eventFromMain.data.sabC;
        sabD = eventFromMain.data.sabD;
        sabI = eventFromMain.data.sabI;
        sabW = eventFromMain.data.sabW;
        sabPos = eventFromMain.data.sabPos;
        sabCanvas = eventFromMain.data.sabCanvas;
        sabCom = eventFromMain.data.sabCom;
        sabNeuronCircle = eventFromMain.data.sabNeuronCircle;
        sabIsPlaying = eventFromMain.data.sabIsPlaying;
        simulationWorkerChannelPort = eventFromMain.data.simulationWorkerChannelPort;
        
        sabNumA = new Float64Array(sabA);
        sabNumB = new Float64Array(sabB);
        sabNumC = new Int16Array(sabC);
        sabNumD = new Int16Array(sabD);
        sabNumI = new Float64Array(sabI);
        sabNumW = new Float64Array(sabW);
        sabNumPos = new Uint32Array(sabPos);            
        sabNumCom = new Int16Array(sabCom);
        sabNumNeuronCircle = new Int16Array(sabNeuronCircle);
        sabNumIsPlaying = new Int16Array(sabIsPlaying);
        simulationWorkerChannelPort.postMessage(200);

        await sleep(1000);

        console.log("init end")
        let prevCircleFlag = false;

        while (true){
            // console.log("init end con" )
            for (let ch = 0; ch<neuronSize;ch++){
                // try{
                    let temp = Module.getCanvasBuffer(ch);
                    // temp.fill(Math.random(1000));
                    // console.log(canvasBuffersNum);
                    canvasBuffersNum[ch].set(temp);
                    if (ch==0) {
                        let temp2 = Module.getCurrentPosition(0);
                        sabNumPos.fill(temp2);
                        // console.log(temp2);
                    }
                // }catch(ex){
                //     // console.log("canvasBuffers", canvasBuffers);
                // }
            }
            if (sabNumCom[0]==1){
                console.log("Instruction coming in!");
                sabNumCom[0] = -1;
                Module.changeNeuronSimulatorProcess(sabNumA,sabNumB,sabNumC, sabNumD, sabNumI, sabNumW, sabNumPos, canvasBuffers,level, neuronSize,envelopeSize,bufferSize,isPlaying);
            }
            if (sabNumIsPlaying[0]==-1 || sabNumIsPlaying[0]==1){
                Module.changeIsPlayingProcess(sabNumIsPlaying[0]);
                sabNumIsPlaying[0] = 0;
            }
            let circles = Module.getNeuronCircles(neuronSize);
            let circleFlag = false;
            for (let neuronIndex = 0; neuronIndex < neuronSize; neuronIndex++){
                if (circles[neuronIndex]==1){
                    sabNumNeuronCircle[neuronIndex] = 1;
                    circleFlag = true;
                }
            }
            if (circleFlag){
                simulationWorkerChannelPort.postMessage(1);
                prevCircleFlag = circleFlag;
            }else{
                if (prevCircleFlag != circleFlag){
                    for (let neuronIndex = 0; neuronIndex < neuronSize; neuronIndex++){
                        sabNumNeuronCircle[neuronIndex] = 0;
                        circleFlag = true;
                    }
        
                    simulationWorkerChannelPort.postMessage(1);
                    prevCircleFlag = 0;
                }
            }

            
            // console.log(canvasBuffersNum[0].subarray(0,10));

            // console.log(temp.subarray(0,10));
        }
        // vm.onmessage = tempOnMessage;
    
    
    }
}  



self.importScripts("neuronsimulator.js"); 
self.Module.onRuntimeInitialized = async _ => {
    console.log("Runtime Initialized");
    // let sabA = new SharedArrayBuffer( neuronSize * Float64Array.BYTES_PER_ELEMENT );
    // let sabB = new SharedArrayBuffer( neuronSize * Float64Array.BYTES_PER_ELEMENT );
    // let sabC = new SharedArrayBuffer( neuronSize * Int16Array.BYTES_PER_ELEMENT );
    // let sabD = new SharedArrayBuffer( neuronSize * Int16Array.BYTES_PER_ELEMENT );
    // let sabI = new SharedArrayBuffer( neuronSize * Int16Array.BYTES_PER_ELEMENT );
    // let sabW = new SharedArrayBuffer( neuronSize * Int16Array.BYTES_PER_ELEMENT );
    // let sabPos = new SharedArrayBuffer( neuronSize * Uint32Array.BYTES_PER_ELEMENT );
    // sabNumA = new Float64Array(sabA);
    // sabNumB = new Float64Array(sabB);
    // sabNumC = new Int16Array(sabC);
    // sabNumD = new Int16Array(sabD);
    // sabNumI = new Int16Array(sabI);
    // sabNumW = new Int16Array(sabW);
    // sabNumPos = new Uint32Array(sabPos);      

    // functions = new Module.changeIsPlayingProcess;
    // const dataByteSize = neuronSize * bufferSize * 30;
    // let arr = Module.HEAPF64.subarray(0,300);
    // const dataPtr = Module._malloc(dataByteSize);
    // console.log("Neurons", Module.changeIsPlayingProcess(-1));
    
    // let sabCanvas = [];
    // for (let i = 0;i<neuronSize;i++){
    //     let sab = new SharedArrayBuffer( neuronSize * Float64Array.BYTES_PER_ELEMENT )        
    //     sabCanvas.push(sab);
    // }
    await sleep(300)
    canvasBuffers = sabCanvas;

    canvasBuffersNum = [];
    
    for (let i=0;i<neuronSize;i++){
        canvasBuffersNum.push(new Float64Array(canvasBuffers[i]));
    //     // var buf = Module._malloc(bufferSize * Float64Array.BYTES_PER_ELEMENT);
    //     var buf = i*bufferSize;
    //     canvasBuffers.push(buf)
    }
    console.log("buf");
    console.log(canvasBuffersNum);
    // console.log(Module);

    console.log("Neuron", Module.changeNeuronSimulatorProcess(sabNumA,sabNumB,sabNumC, sabNumD, sabNumI, sabNumW, sabNumPos, canvasBuffers,level, neuronSize,envelopeSize,bufferSize,isPlaying));
    // while(true){
    //     callMe();
    // }
    // let arr = Module.HEAPF64.subarray(0,30);
    // console.log(arr);

}; 

function callMe(a){
    // let arr = Module.HEAPF64.subarray(0,bufSize);
    // console.log(arr);
    console.log(tempBufferNum.subarray(0,10));
    
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
