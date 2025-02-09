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

var sabStateBuffer;
var sabMotorCommand;
var sabFirmwareVersion;
var sabDistanceBuf;
var websocketMessageChannelSend;


self.onmessage = async function(eventFromMain){
    switch (eventFromMain.data.message){
        case "INITIALIZE":
            // console.log("INITIALIZED_WEB_SOCKET PROXY");
            sabStateBuffer = eventFromMain.data.sabStateBuffer;
            sabMotorCommand = eventFromMain.data.sabMotorCommand;
            sabFirmwareVersion = eventFromMain.data.sabFirmwareVersion;
            sabDistanceBuf = eventFromMain.data.sabDistanceBuf;
            websocketMessageChannelSend = eventFromMain.data.websocketMessageChannelSend;

            postMessage({
                message:'INITIALIZED_WEB_SOCKET_PROXY',
            });
        
        break;
        case "START_PROXY":
            // wake thread
            startProxyCommand();

        break;

    }
}


function startProxyCommand(){
    console.log("START_WEB_SOCKET_PROXY");
    console.log("WAITING FOR COMMANDS", sabStateBuffer);
    
    Atomics.store(sabStateBuffer, STATE.BATTERY_STATUS, 0);
    Atomics.store(sabStateBuffer, STATE.COMMAND_MOTORS, 0);
    sabStateBuffer[STATE.COMMAND_MOTORS] = 0;
    sabStateBuffer[STATE.WEB_SOCKET]++;

    // while (Atomics.wait(sabStateBuffer, STATE.COMMAND_MOTORS, 0) === "ok"){
    // console.log("RECEIVE COMMAND0", sabStateBuffer[STATE.COMMAND_MOTORS_LENGTH], sabStateBuffer[STATE.COMMAND_MOTORS]);
    while (Atomics.wait(sabStateBuffer, STATE.COMMAND_MOTORS, 0) === "ok"){
        // console.log("RECEIVE COMMAND", sabStateBuffer[STATE.COMMAND_MOTORS_LENGTH], sabStateBuffer[STATE.COMMAND_MOTORS]);
        // if (sabStateBuffer[STATE.WEB_SOCKET] === -100 ) {
        // }

        if ( sabStateBuffer[STATE.COMMAND_MOTORS_LENGTH] > 0) {
            try {
                let messageString = "";
                const messageLength = sabStateBuffer[STATE.COMMAND_MOTORS_LENGTH];
                for (let i = 0; i < messageLength; i++) {
                    messageString = messageString + String.fromCharCode(sabMotorCommand[i]);
                }
                websocketMessageChannelSend.postMessage({"message": "MESSAGE", "webSocketMessage": messageString});
                // console.log('webSocketChannel.readyState',  messageString);                            
            } catch (err) {
                console.log("Proxy error: ", err);
            }
        }

        Atomics.store(sabStateBuffer, STATE.COMMAND_MOTORS, 0);            
    }
    console.log("PROXY CRASHED");
    setTimeout(startProxyCommand, 500);
}
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
