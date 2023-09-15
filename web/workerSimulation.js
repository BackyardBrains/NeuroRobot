let ptrCanvasBuffer;
let ptrNeuronCircle;
let allocatedCanvasBuffer;
let selectedIdx=-1;
let neuronSize = 2;
let windowSize = 200 * 30;
let sabA;
let sabB;
let sabC;
let sabD;
let sabI;
let sabW;
let sabPos;
let sabConnectome;
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
let sabNumConnectome;
let sabNumCom;
let sabNumNeuronCircle;
let abPrevNumNeuronCircle;
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
        sabConfig = eventFromMain.data.sabConfig;
        sabConnectome = eventFromMain.data.sabConnectome;
        // sabCanvas = eventFromMain.data.sabCanvas;
        sabCom = eventFromMain.data.sabCom;
        sabNeuronCircle = eventFromMain.data.sabNeuronCircle;
        sabIsPlaying = eventFromMain.data.sabIsPlaying;
        simulationWorkerChannelPort = eventFromMain.data.simulationWorkerChannelPort;
        initializeChannelPort = eventFromMain.data.initializeChannelPort;
        abPrevNumNeuronCircle = new Int16Array(neuronSize);
        
        sabNumA = new Float64Array(sabA);
        sabNumB = new Float64Array(sabB);
        sabNumC = new Int16Array(sabC);
        sabNumD = new Int16Array(sabD);
        sabNumI = new Float64Array(sabI);
        sabNumW = new Float64Array(sabW);
        sabNumPos = new Uint16Array(sabPos);            
        sabNumConnectome = new Float64Array(sabConnectome);
        sabNumCom = new Int16Array(sabCom);
        // sabNumNeuronCircle = new Int16Array(sabNeuronCircle);
        sabNumIsPlaying = new Int16Array(sabIsPlaying);
        sabNumConfig = new Uint32Array(sabConfig);
        simulationWorkerChannelPort.postMessage(200);

        await sleep(1000);

        console.log("init end")
        let prevCircleFlag = false;

        while (true){
            // console.log("init end con" )
            if (sabNumConfig[0] != 0){
                selectedIdx = sabNumConfig[0];
                sabNumConfig[0] = 0;
                Module.changeIdxSelectedProcess(selectedIdx);
                // console.log("sabNumNeuronCircle");
                // console.log(sabNumNeuronCircle);
            }
            // selectedIdx=sabNumConfig[0];
            let temp2 = Module.getCurrentPosition(0);
            sabNumPos.fill(temp2);

            // for (let ch = 0; ch<neuronSize;ch++){
            //     // try{
            //         // temp.fill(Math.random(1000));
            //         // console.log(canvasBuffersNum);
            //         if (selectedIdx!=-1 && ch==selectedIdx) {
            //             // let temp = Module.getCanvasBuffer(ch);
            //             // allocatedCanvasBuffer.set(temp);
            //             // canvasBuffersNum[0].set(temp);
            //             let temp2 = Module.getCurrentPosition(0);
            //             sabNumPos.fill(temp2);

            //         }
            //     // }catch(ex){
            //     //     // console.log("canvasBuffers", canvasBuffers);
            //     // }
            // }
            if (sabNumConfig[1]==1){
                Module.stopThreadProcess(0)
                sabNumConfig[1] = 0;
            }

            if (sabNumCom[0]==1){
                console.log("Instruction coming in!");
                sabNumCom[0] = -1;
                // changeNeuronSimulatorProcess(const val &__a, const val &__b, const val &__c, const val &__d, const val &__i, const val &__w, const val &__canvasPointers, const val &__positions, const val &__connectome, 
                //     short _level, int32_t _neuronLength, int32_t _envelopeSize, int32_t _bufferSize, short _isPlaying){
                // Module.changeNeuronSimulatorProcess(sabNumA,sabNumB,sabNumC, sabNumD, sabNumI, sabNumW, canvasBuffers, sabNumPos, sabNumConnectome, level, neuronSize,envelopeSize,bufferSize,isPlaying);
            }
            if (sabNumIsPlaying[0]==-1 || sabNumIsPlaying[0]==1){
                Module.changeIsPlayingProcess(sabNumIsPlaying[0]);
                sabNumIsPlaying[0] = 0;
            }
            // if (sabNumConfig[0]!=-1){
            // }

            // let circles = Module.getNeuronCircles(neuronSize);
            // let circleFlag = false;
            // for (let neuronIndex = 0; neuronIndex < neuronSize; neuronIndex++){
            //     sabNumNeuronCircle[neuronIndex] = circles[neuronIndex];
            //     if (sabNumNeuronCircle[neuronIndex] != abPrevNumNeuronCircle[neuronIndex]){
            //         circleFlag = true;
            //     }
            // }
            // // abPrevNumNeuronCircle.set(sabNumNeuronCircle);
            // if (circleFlag){
            //     simulationWorkerChannelPort.postMessage(1);
            //     prevCircleFlag = circleFlag;
            // }else{
            //     if (prevCircleFlag != circleFlag){
            //         for (let neuronIndex = 0; neuronIndex < neuronSize; neuronIndex++){
            //             sabNumNeuronCircle[neuronIndex] = 0;
            //             circleFlag = true;
            //         }
        
            //         simulationWorkerChannelPort.postMessage(1);
            //         prevCircleFlag = 0;
            //     }
            // }

            
            // console.log(canvasBuffersNum[0].subarray(0,10));

            // console.log(temp.subarray(0,10));
        }
        // vm.onmessage = tempOnMessage;
    
    
    }
}  



self.importScripts("neuronprototype.js"); 
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
    await sleep(700);
    ptrCanvasBuffer = Module._malloc(windowSize * Module.HEAPF64.BYTES_PER_ELEMENT);
    // allocatedCanvasBuffer=Module.HEAPF64.subarray(ptrCanvasBuffer/Module.HEAPF64.BYTES_PER_ELEMENT, ptrCanvasBuffer/Module.HEAPF64.BYTES_PER_ELEMENT + windowSize);
    const start = ptrCanvasBuffer/Module.HEAPF64.BYTES_PER_ELEMENT;
    allocatedCanvasBuffer = Module.HEAPF64.subarray( start, (start + windowSize ));

    ptrNeuronCircle = Module._malloc(neuronSize * Module.HEAP16.BYTES_PER_ELEMENT);
    const startNeuron = ptrNeuronCircle/Module.HEAP16.BYTES_PER_ELEMENT;
    sabNumNeuronCircle = Module.HEAP16.subarray( startNeuron, (startNeuron + neuronSize ));
    // let tempSabNumNeuronCircle = Module.HEAP16.subarray( startNeuron, (startNeuron + neuronSize ));

    initializeChannelPort.postMessage({
        allocatedCanvasbuffer: allocatedCanvasBuffer,
        sabNumNeuronCircle: sabNumNeuronCircle,
        // sabNumNeuronCircle: tempSabNumNeuronCircle,
    });


    const test = Module.ccall(
        'passPointer',
        'number',
        ['number', 'number'],
        [ptrCanvasBuffer, ptrNeuronCircle]
    );
    // console.log("test");
    // console.log(test);
    
    // Module.ccall();
    // Module.HEAPF64.set(list2  , maloc/Module.HEAPF64.BYTES_PER_ELEMENT);

    // canvasBuffers = sabCanvas;

    // canvasBuffersNum = [];
    
    // for (let i=0;i<1;i++){
    //     canvasBuffersNum.push(new Float64Array(canvasBuffers[i]));
    // //     // var buf = Module._malloc(bufferSize * Float64Array.BYTES_PER_ELEMENT);
    // //     var buf = i*bufferSize;
    // //     canvasBuffers.push(buf)
    // }
    // console.log("buf");
    // console.log(canvasBuffersNum);
    // console.log(Module);
    
    // console.log(sabNumA,sabNumB,sabNumC, sabNumD, sabNumI, sabNumW, canvasBuffers, sabNumPos, sabNumConnectome, level, neuronSize,envelopeSize,bufferSize,isPlaying);
    console.log("Neuron", Module.changeNeuronSimulatorProcess(sabNumA,sabNumB,sabNumC, sabNumD, sabNumI, sabNumW, canvasBuffers, sabNumPos, sabNumConnectome, level, neuronSize,envelopeSize,bufferSize,isPlaying));
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
