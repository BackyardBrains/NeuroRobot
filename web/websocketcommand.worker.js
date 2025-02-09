var wsConnection;
const StateLength = 70;
const COLOR_CHANNELS = 4;
const cameraWidth = 320;
const cameraHeight = 240;
let processedCommandIndex = -1;

let neuronSize = 1;

var sabStateBuffer;
var sabMotorCommand;
var sabFirmwareVersion;
var sabDistanceBuf;
var websocketMessageChannelReceive;

let gracefulDisconnect = false;
const webSocketLink = 'ws://192.168.4.1:80/ws';
var webSocketChannel;
var WebSocketStateEnum = {CONNECTING: 0, OPEN: 1, CLOSING: 2, CLOSED: 3};
const url = "http://192.168.4.1:81/stream";
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

let timeoutId;
function startWebSocket() {
    clearTimeout(timeoutId); 
    console.log("STARTING WEBSOCKET!!!");
    webSocketChannel = new WebSocket(webSocketLink);
    timeoutId = setTimeout(() => {
        if (webSocketChannel.readyState === WebSocket.CONNECTING) {
          console.error('WebSocket connection timed out');
          try {
            webSocketChannel.close(); 
          }catch(err) {
            console.error(err);
          }
        }
      }, 7000);
    webSocketChannel.onopen = () => {
        console.log('ON OPEN: Connected to WebSocket server');
        clearTimeout(timeoutId); 
        webSocketChannel.send(offLEDCmd + stopMotorCmd);
        webSocketChannel.send("v:");
        if (sabStateBuffer[STATE.WEB_SOCKET] === -100 ) {
            gracefulDisconnect = true;
            sabStateBuffer[STATE.WEB_SOCKET] = -200;
            // console.log("STOP NOW!!!");
            webSocketChannel.send(greenLEDCmd + stopMotorCmd);
        }
        sabStateBuffer[STATE.WEB_SOCKET]++;
        Atomics.store(sabStateBuffer, STATE.WEB_SOCKET, 1);
    };
    
    webSocketChannel.onmessage = (event) => {
        try{
            if (event.data.indexOf("V") < 0) { // not firmware
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
                sabDistanceBuf[0] = distance;
                // console.log("sabStateBuffer[STATE.WEB_SOCKET]: ", sabStateBuffer[STATE.WEB_SOCKET]);
                /* WRITE TO WEBSOCKET
                if ( sabStateBuffer[STATE.COMMAND_MOTORS_LENGTH] > 0) {
                    if (processedCommandIndex != sabStateBuffer[STATE.COMMAND_MOTORS]) {
                        processedCommandIndex = sabStateBuffer[STATE.COMMAND_MOTORS];
                        let messageString = "";
                        const messageLength = sabStateBuffer[STATE.COMMAND_MOTORS_LENGTH];
                        for (let i = 0; i < messageLength; i++) {
                            messageString = messageString + String.fromCharCode(sabMotorCommand[i]);
                        }
                        // console.log("msgstring:", messageString);
                        if (webSocketChannel !== undefined) {
                            if (webSocketChannel.readyState === WebSocket.OPEN) {
                                try{
                                    webSocketChannel.send(messageString);
                                }catch(err){
                                    console.log("abort");
                                }
                    
                            }
                        }
                    }
                }
                    */
                console.log("error decoding", err);
            } else {
                const message = event.data.replaceAll("V", "");
                const arr = message.split(".");
                sabFirmwareVersion[0] = parseInt(arr[0]);
                sabFirmwareVersion[1] = parseInt(arr[1]);
                sabFirmwareVersion[2] = parseInt(arr[2]);
            }
        }catch(err){

        }
    };
    
    webSocketChannel.onerror = async (error) => {
        console.error('WebSocket Error:', error);
        clearTimeout(timeoutId);         
        Atomics.store(sabStateBuffer, STATE.BATTERY_STATUS, -2);
        try{
            if (webSocketChannel.readyState == WebSocketStateEnum.OPEN) {
                webSocketChannel.close();
            } else {
                webSocketChannel = null;
            }        
        }catch(err){
            console.log("abort");
        }
        // console.log("webSocketChannel.readyState: ", webSocketChannel.readyState);
        // sleep(300).then(async ()=>{
        //     try{
        //         webSocketChannel.close();
        //     }catch(err){
        //         console.log("abort");
        //     }
        //     await sleep(200);
        //     postMessage({
        //         message: "STOP_WEBSOCKET"
        //     });
        // });

    };
    
    webSocketChannel.onclose = (event) => {
        clearTimeout(timeoutId); 
        Atomics.store(sabStateBuffer, STATE.BATTERY_STATUS, -1);

        console.log('WebSocket connection closed:', event.code, event.reason);
        if (event.code == 1000) {
        } else if (event.code == 1005 && gracefulDisconnect) {
            gracefulDisconnect = false;
        } else {
            if (gracefulDisconnect) {
                gracefulDisconnect = false;
                return;
            } else {
                startWebSocket();
                return;
            }
        }

        // sleep(300).then(async ()=>{
        //     try{
        //         webSocketChannel.close();
        //     }catch(err){
        //         console.log("abort");
        //     }
        //     await sleep(200);
        //     postMessage({
        //         message: "STOP_WEBSOCKET"
        //     });
        // });

    };
}

self.onmessage = async function(eventFromMain){
    switch (eventFromMain.data.message){
        case "INITIALIZE":
            console.log("INITIALIZED_WEB_SOCKET");
            sabStateBuffer = eventFromMain.data.sabStateBuffer;
            sabMotorCommand = eventFromMain.data.sabMotorCommand;
            sabFirmwareVersion = eventFromMain.data.sabFirmwareVersion;
            sabDistanceBuf = eventFromMain.data.sabDistanceBuf;
            websocketMessageChannelReceive = eventFromMain.data.websocketMessageChannelReceive;
            Atomics.store(sabStateBuffer, STATE.BATTERY_STATUS, 0);
            websocketMessageChannelReceive.onmessage = async function(event) {
                switch (event.data.message){
                    case "MESSAGE":
                        const messageString = event.data.webSocketMessage;
                        // console.log("MESSAGE: ", messageString);
                        if (messageString !== undefined) {
                            if (webSocketChannel !== undefined) {
                                if (webSocketChannel.readyState === WebSocket.OPEN) {
                                    try{
                                        webSocketChannel.send(messageString);
                                    }catch(err){
                                        console.log("abort websocket issue");
                                    }
                        
                                }
                            }        
                        }
                    break;
                };
            };
            

            postMessage({
                message:'INITIALIZED_WEB_SOCKET',
            });
        
        break;
        case "CLOSE":
            if (sabStateBuffer[STATE.WEB_SOCKET] === -100 ) {
                gracefulDisconnect = true;
                sabStateBuffer[STATE.WEB_SOCKET] = -200;
                // console.log("STOP NOW!!!");
                webSocketChannel.send(greenLEDCmd + stopMotorCmd);
                sleep(700).then(async ()=>{
                    gracefulDisconnect = true;
                    webSocketChannel.send(greenLEDCmd + stopMotorCmd);
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
            } else
            if (sabStateBuffer[STATE.WEB_SOCKET] === -200) {
                return;
            }
        break;
        case "START":
            // wake thread
            console.log("START_WEB_SOCKET");
            
            Atomics.store(sabStateBuffer, STATE.BATTERY_STATUS, 0);
            // Atomics.store(sabStateBuffer, STATE.COMMAND_MOTORS, 0);
            startWebSocket();

            return;
            await sleep(2000);
                    
            console.log("WAITING FOR COMMANDS", sabStateBuffer);
            // while (Atomics.wait(sabStateBuffer, STATE.COMMAND_MOTORS, 0) === "ok"){
            while (Atomics.wait(sabStateBuffer, STATE.COMMAND_MOTORS, 0) === "ok"){
                console.log("RECEIVE COMMAND", sabStateBuffer[STATE.WEB_SOCKET]);
                if (sabStateBuffer[STATE.WEB_SOCKET] === -100 ) {
                }

                if ( sabStateBuffer[STATE.COMMAND_MOTORS_LENGTH] > 0) {
                    let messageString = "";
                    const messageLength = sabStateBuffer[STATE.COMMAND_MOTORS_LENGTH];
                    for (let i = 0; i < messageLength; i++) {
                        messageString = messageString + String.fromCharCode(sabMotorCommand[i]);
                    }
                    console.log('webSocketChannel.readyState',  messageString);
                }
                
                Atomics.store(sabStateBuffer, STATE.COMMAND_MOTORS, 0);            
            }
        break;

    }
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
