const StateLength = 10;
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
            const SOI = new Uint8Array(2);
            SOI[0] = 0xFF;
            SOI[1] = 0xD8;
            const CONTENT_LENGTH = 'content-length';
            const TYPE_JPEG = 'image/jpeg';
            let image = document.getElementById('image');
      
            fetch(url)
            .then(response => {
                if (!response.ok) {
                    throw Error(response.status+' '+response.statusText)
                }
      
                if (!response.body) {
                    throw Error('ReadableStream not yet supported in this browser.')
                }
                
                const reader = response.body.getReader();
      
                let headers = '';
                let contentLength = -1;
                let imageBuffer = null;
                let bytesRead = 0;
      
      
                // calculating fps. This is pretty lame. Should probably implement a floating window function.
                let frames = 0;
                
                // setInterval(() => {
                //     console.log("fps : " + frames);
                //     frames = 0;
                // }, 1000) 
      
      
                const read = () => {      
                    reader.read().then(({done, value}) => {
                        if (done) {
                            controller.close();
                            return;
                        }
                        
                        for (let index =0; index < value.length; index++) {
                            
                            // we've found start of the frame. Everything we've read till now is the header.
                            if (value[index] === SOI[0] && value[index+1] === SOI[1]) {
                                contentLength = getLength(headers);
                                imageBuffer = new Uint8Array(new ArrayBuffer(contentLength));
                            }
                            // we're still reading the header.
                            if (contentLength <= 0) {
                                headers += String.fromCharCode(value[index]);
                            }
                            // we're now reading the jpeg. 
                            else if (bytesRead < contentLength){
                                imageBuffer[bytesRead++] = value[index];
                            }
                            // we're done reading the jpeg. Time to render it. 
                            else {
                                // console.log("jpeg read with bytes : " + bytesRead);
                                let frame = URL.createObjectURL(new Blob([imageBuffer], {type: "video/x-motion-jpeg"})) 
                                // change JPG into canvas buffer
                                const offscreenCanvas = new OffscreenCanvas(frame.width, frame.height);
                                const ctx = offscreenCanvas.getContext('bitmaprenderer');
                                
                                ctx.drawImage(frame, 0, 0);
                                
                                const pixelData = ctx.getImageData(0, 0, frame.width, frame.height).data;
                                ptrCameraDrawBuffer.set(pixelData);
                                //Notify to process image
                                Atomics.notify(bufStateArray, STATE.PREPROCESS_IMAGE, 1);

                                
                                frames++;
                                contentLength = 0;
                                bytesRead = 0;
                                headers = '';
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