var wsConnection;
const StateLength = 70;
const COLOR_CHANNELS = 4;
const cameraWidth = 320;
const cameraHeight = 240;

let neuronSize = 1;

var sabStateBuffer;
var sabMotorCommand;

const webSocketLink = 'ws://192.168.4.1:80/ws';
var webSocketChannel;
var WebSocketStateEnum = {CONNECTING: 0, OPEN: 1, CLOSING: 2, CLOSED: 3};
const url = "http://192.168.4.1:81/stream";
// const url = "http://192.168.1.4:8081";
const offLEDCmd = "d:0,0,0,0;d:1,0,0,0;d:2,0,0,0;d:3,0,0,0;";
const redLEDCmd = "d:0,255,0,0;d:1,255,0,0;d:2,255,0,0;d:3,255,0,0;";
const greenLEDCmd = "d:0,0,255,0;d:1,0,255,0;d:2,0,255,0;d:3,0,255,0;";
const blueLEDCmd = "d:0,0,0,255;d:1,0,0,255;d:2,0,0,255;d:3,0,0,255;";
const stopMotorCmd = "l:0;r:0;s:0;";

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


function startWebSocket() {
    console.log("STARTING WEBSOCKET!!!");
    webSocketChannel = new WebSocket(webSocketLink);
    webSocketChannel.onopen = () => {
        console.log('Connected to WebSocket server');
        webSocketChannel.send(offLEDCmd + stopMotorCmd);
        Atomics.store(sabStateBuffer, STATE.WEB_SOCKET, 1);
    };
    
    webSocketChannel.onmessage = (event) => {
        // console.log('Received message from server:', event.data);
        const arrData = event.data.split(",");
        const distance = arrData[2];
        let batteryPercent = 80;

        const baseBottomBattery = (arrData[3]) - 590;
        batteryPercent = Math.floor(baseBottomBattery / 278 * 100);
        if (batteryPercent > 100) {
          batteryPercent = 100;
        } else if (batteryPercent <= 0) {
          batteryPercent = 0;
        }
        Atomics.store(sabStateBuffer, STATE.BATTERY_STATUS, batteryPercent);
        // Atomics.store(sabStateBuffer, STATE.DISTANCE_STATUS, distance);
        // if (sabDistanceBuf[0] != distance) {
        //     console.log("distance: ", distance);
        // }
        sabDistanceBuf[0] = distance;

        if (sabStateBuffer[STATE.WEB_SOCKET] === -100 ) {
            webSocketChannel.send(greenLEDCmd + stopMotorCmd);
            sleep(300).then(async ()=>{
                try{
                    webSocketChannel.close();
                }catch(err){
                    console.log("abort");
                }
                await sleep(200);
                postMessage({
                    message: "STOP_WEBSOCKET"
                });
            });
            return;        
        }

        if ( sabStateBuffer[STATE.COMMAND_MOTORS_LENGTH] > 0) {
            let messageString = "";
            const messageLength = sabStateBuffer[STATE.COMMAND_MOTORS_LENGTH];
            for (let i = 0; i < messageLength; i++) {
                messageString = messageString + String.fromCharCode(sabMotorCommand[i]);
            }
            if (webSocketChannel !== undefined) {
                // console.log('webSocketChannel.readyState', webSocketChannel.readyState, messageString);
                if (webSocketChannel.readyState === WebSocket.OPEN) {
                    webSocketChannel.send(messageString);
                }
            }
        }

        // sabStateBuffer[STATE.DISTANCE_STATUS] = distance;

    };
    
    webSocketChannel.onerror = (error) => {
        // sabStateBuffer[STATE.WEB_SOCKET] = -2;
        Atomics.store(sabStateBuffer, STATE.BATTERY_STATUS, -2);
        console.error('WebSocket Error:', error);
        if (webSocketChannel.readyState == WebSocketStateEnum.OPEN) {
            webSocketChannel.close();
        } else {
            webSocketChannel = null;
        }        
    };
    
    webSocketChannel.onclose = (event) => {
        // sabStateBuffer[STATE.WEB_SOCKET] = -1;
        Atomics.store(sabStateBuffer, STATE.BATTERY_STATUS, -1);

        console.log('WebSocket connection closed:', event.code, event.reason);
    };
}

self.onmessage = async function(eventFromMain){
    switch (eventFromMain.data.message){
        case "INITIALIZE":
            console.log("INITIALIZED_WEB_SOCKET");
            sabStateBuffer = eventFromMain.data.sabStateBuffer;
            // sabStateBuffer = new Int32Array(new SharedArrayBuffer(100));
            sabMotorCommand = eventFromMain.data.sabMotorCommand;
            sabDistanceBuf = eventFromMain.data.sabDistanceBuf;
            // sabStateBuffer[STATE.WEB_SOCKET] = 0;
            Atomics.store(sabStateBuffer, STATE.BATTERY_STATUS, 0);

            postMessage({
                message:'INITIALIZED_WEB_SOCKET',
                // "sabStateCommand": sabStateBuffer,
            });
        
        break;
        case "START":
            // wake thread
            console.log("START_WEB_SOCKET");
            
            Atomics.store(sabStateBuffer, STATE.BATTERY_STATUS, 0);
            Atomics.store(sabStateBuffer, STATE.COMMAND_MOTORS, 0);
            // sabStateBuffer[STATE.WEB_SOCKET] = 0;
            // sabStateBuffer[STATE.COMMAND_MOTORS] = 0;
            startWebSocket();
            return;
            await sleep(2000);
                    
            console.log("WAITING FOR COMMANDS", sabStateBuffer);
            // while (Atomics.wait(sabStateBuffer, STATE.COMMAND_MOTORS, 0) === "ok"){
            while (Atomics.wait(sabStateBuffer, STATE.COMMAND_MOTORS, 0) === "ok"){
                console.log("RECEIVE COMMAND", sabStateBuffer[STATE.WEB_SOCKET]);
                if (sabStateBuffer[STATE.WEB_SOCKET] === -100 ) {
                    // webSocketChannel.send(greenLEDCmd + stopMotorCmd);
                    // try{
                    //     webSocket.close();
                    // }catch(err){
                    //     console.log("abort");
                    // }
                    // postMessage({
                    //     message: "STOP_WEBSOCKET"
                    // });
                    // return;        
                }

                if ( sabStateBuffer[STATE.COMMAND_MOTORS_LENGTH] > 0) {
                    let messageString = "";
                    const messageLength = sabStateBuffer[STATE.COMMAND_MOTORS_LENGTH];
                    for (let i = 0; i < messageLength; i++) {
                        messageString = messageString + String.fromCharCode(sabMotorCommand[i]);
                    }
                    console.log('webSocketChannel.readyState',  messageString);
                    // if (webSocketChannel !== undefined) {
                    //     if (webSocketChannel.readyState === WebSocket.OPEN) {
                    //         webSocketChannel.send(messageString);
                    //     }
                    // }
                }
                
                Atomics.store(sabStateBuffer, STATE.COMMAND_MOTORS, 0);            

                // const messageLength = sabStateBuffer[STATE.COMMAND_MOTORS_LENGTH];
                // const message = new TextDecoder("utf-8").decode( sabMotorCommand.slice(0, messageLength) );
                // webSocketChannel.send(message);
                
                // sabStateBuffer[STATE.COMMAND_MOTORS] = 0;

                // only call wasm function - pass pointer esp vis_pref_vals
            }
        break;

    }
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
