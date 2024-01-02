var wsConnection;
const StateLength = 20;
const COLOR_CHANNELS = 4;
const cameraWidth = 320;
const cameraHeight = 240;

let neuronSize = 1;

var sabStateBuffer;
var sabMotorCommand;

const webSocketCommandUrl = "ws://192.168.4.1/ws";

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




self.onmessage = function(eventFromMain){
    switch (eventFromMain.data.message){
        case "INITIALIZE":
            sabStateBuffer = eventFromMain.data.sabStateBuffer;
            sabMotorCommand = eventFromMain.data.sabMotorCommand;
            wsConnection = new WebSocket(webSocketCommandUrl);
            postMessage({
                message:'INITIALIZED_WEB_SOCKET',
            });
        
        break;
        case "START":
            // wake thread
            while (Atomics.wait(sabStateBuffer, STATE.COMMAND_MOTORS, 0) === "ok"){
                const messageLength = sabStateBuffer[STATE.COMMAND_MOTORS_LENGTH];
                const message = new TextDecoder("utf-8").decode( sabMotorCommand.slice(0, messageLength) );
                wsConnection.send(message);

                // only call wasm function - pass pointer esp vis_pref_vals
            }
        break;

    }
}