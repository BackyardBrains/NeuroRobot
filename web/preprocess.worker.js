var ptrStateBuffer;
var bufStateArray;
var ptrCameraDrawBuffer;
var bufCameraDrawArray;
const url = "http://192.168.4.1:81/stream";

const STATE = {
    "WEB_SOCKET":0,
    "PREPROCESS_IMAGE":1,
    "COMMAND_MOTORS":2,
};

self.onmessage = function(eventFromMain){
    switch (eventFromMain.data.message){
        case "INIT":
            ptrStateBuffer = eventFromMain.data.ptrStateBuffer;
            bufStateArray = new Int32Array(ptrStateBuffer);
            ptrCameraDrawBuffer = eventFromMain.data.ptrCameraDrawBuffer;
            bufCameraDrawArray = new Int32Array(ptrCameraDrawBuffer);
        break;
        case "START":
            // wake thread
            while (Atomics.wait(bufStateArray, STATE.PREPROCESS_IMAGE, 0) === "ok"){
                // only call wasm function - pass pointer esp vis_pref_vals
                // output : change vis_pref_vals pointer so it can be processed by neuronSimulator.
                Atomics.store(bufStateArray, STATE.PREPROCESS_IMAGE, 0);
            }
        break;

    }
}