
if use_esp32
    large_frame = snapshot(rak_cam);
    esp_get_serial
elseif use_webcam
    trigger(rak_cam)
    large_frame = getdata(rak_cam, 1);
elseif rak_only
    large_frame = rak_cam.readVideo();
    large_frame = permute(reshape(large_frame, 3, rak_cam.readVideoWidth(), rak_cam.readVideoHeight()),[3,2,1]);
    this_audio = double(rak_cam.readAudio());
    serial_receive = rak_cam.readSerial();
end

if exist('dev_mode', 'var') && dev_mode
    brainless
end

% disp(serial_receive)