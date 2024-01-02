const StateLength = 20;
var ptrStateBuffer;
var bufStateArray;
var ptrCameraDrawBuffer;
var bufCameraDrawArray;
const frameWidth = 320;
const frameHeight = 240;
let frames = 0;
// let offscreenCanvas;
// let ctx;
// let imgData;
// const imgBuf = new Image();

const url = "http://192.168.4.1:81/stream";
// const url = "http://192.168.1.5:8081";

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
            sabCameraDrawBuffer = eventFromMain.data.sabCameraDrawBuffer;

            offscreenCanvas = eventFromMain.data.offscreenCanvas;
            console.log(offscreenCanvas);
            // ctx = offscreenCanvas.getContext('2d');
            // imgData = ctx.createImageData(frameWidth, frameHeight);

            postMessage({
                message: "INITIALIZED"
            });
        break;
        case "START":
            console.log("!!!START");
            const SOI = new Uint8Array(2);
            SOI[0] = 0xFF;
            SOI[1] = 0xD8;
            const CONTENT_LENGTH = 'content-length';
            const TYPE_JPEG = 'image/jpeg';
            // let image = document.getElementById('image');
      
            fetch(url)
            .then(response => {
                if (!response.ok) {
                    throw Error(response.status+' '+response.statusText)
                }
                console.log("!!!RESPONSE OK");
      
                if (!response.body) {
                    throw Error('ReadableStream not yet supported in this browser.')
                }
                
                const reader = response.body.getReader();
      
                let headers = '';
                let contentLength = -1;
                let imageBuffer = null;
                let bytesRead = 0;
      
      
                // calculating fps. This is pretty lame. Should probably implement a floating window function.
                // let frames = 0;
                
                // setInterval(() => {
                //     console.log("fps : " + frames);
                //     frames = 0;
                // }, 1000) 
      
      
                const read = () => {      
                    reader.read().then(({done, value}) => {
                        if (done) {
                            // controller.close();
                            console.log("done");
                            return;
                        }
                        
                        for (let index =0; index < value.length; index++) {
                            
                            // we've found start of the frame. Everything we've read till now is the header.
                            if (value[index] === SOI[0] && value[index+1] === SOI[1]) {
                                contentLength = getLength(headers);
                                imageBuffer = new Uint8Array(new ArrayBuffer(contentLength));
                                // console.log("jpeg read with bytes headers : " ,  value);

                            }
                            // we're still reading the header.
                            if (contentLength <= 0) {
                                headers += String.fromCharCode(value[index]);
                                // sabStateBuffer[STATE.CAMERA_CONTENT_COMPLETE] = 0;
                            }
                            // we're now reading the jpeg. 
                            else if (bytesRead < contentLength){
                                // sabStateBuffer[STATE.CAMERA_CONTENT_COMPLETE] = 0;
                                // imageBuffer[bytesRead++] = value[index];
                                imageBuffer[bytesRead++] = value[index];
                            }
                            // we're done reading the jpeg. Time to render it. 
                            else {
                                // self.img = new Image();
                                // if (sabStateBuffer[STATE.CAMERA_CONTENT_COMPLETE] == 0){
                                    sabStateBuffer[STATE.CAMERA_CONTENT_COMPLETE] = frames % 120;
                                    // console.log("COMPLETE? 1", bytesRead);
                                    sabStateBuffer[STATE.CAMERA_CONTENT_LENGTH] = bytesRead;
                                    sabCameraDrawBuffer.set(imageBuffer);
                                // }
                                // console.log("imageBuffer");
                                // console.log(bufCameraDrawArray.length, imageBuffer.length);
                                frames++;
                                contentLength = 0;
                                bytesRead = 0;
                                headers = '';

                                // imgBuf.src = URL.createObjectURL(new Blob([imageBuffer], {type: "video/x-motion-jpeg"})) 
                                // imgBuf.onload = () =>{
                                //     console.log("imgBuf");
                                //     console.log(imgBuf);
                                //     // change JPG into canvas buffer
                                //     const offscreenCanvas = new OffscreenCanvas(imgBuf.width, imgBuf.height);
                                // console.log(offscreenCanvas);
                                    // imgData.data.set(imageBuffer);
                                    // for (let i = 0; i < imgData.data.length; i += 4) {
                                    //     imgData.data[i+0] = 0;
                                    //     imgData.data[i+1] = 255;
                                    //     imgData.data[i+2] = 0;
                                    //     imgData.data[i+3] = 255;
                                    // }                                    
                                    // console.log(imgData);
                                    // ctx.putImageData(imgData,10,10);
                                    
                                //     ctx.drawImage(imgBuf, 0, 0);
                                    
                                //     const pixelData = ctx.getImageData(0, 0, imgBuf.width, imgBuf.height).data;
                                //     ptrCameraDrawBuffer.set(pixelData);
                                //     //Notify to process image
                                //     Atomics.notify(bufStateArray, STATE.PREPROCESS_IMAGE, 1);
                                //     console.log("!!!CAMERA DRAW BUFFER");
    
                                    
                                //     frames++;
                                //     contentLength = 0;
                                //     bytesRead = 0;
                                //     headers = '';
                                // };
                                // URL.revokeObjectURL(frame)
                              }
                        }
      
                        read();
                    }).catch(error => {
                        console.error(error);
                    })
                }
                
                read();
                
            }).catch(error => {
                console.error(error);
            })
      
            const getLength = (headers) => {
                let contentLength = -1;
                headers.split('\n').forEach((header, _) => {
                    const pair = header.split(':');
                    if (pair[0].toLowerCase() === CONTENT_LENGTH) { // Fix for issue https://github.com/aruntj/mjpeg-readable-stream/issues/3 suggested by martapanc
                        contentLength = pair[1];
                    }
                })
                return contentLength;
            };
      
        break;

    }
}