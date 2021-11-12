
if use_esp32
    large_frame = snapshot(rak_cam);
    large_frame = imrotate(large_frame, 270);        
    get_esp_serial
elseif use_webcam
    trigger(rak_cam)
    large_frame = getdata(rak_cam, 1);
elseif rak_only
    large_frame = rak_cam.readVideo();
    large_frame = permute(reshape(large_frame, 3, rak_cam.readVideoWidth(), rak_cam.readVideoHeight()),[3,2,1]);
    this_audio = double(rak_cam.readAudio());
    serial_receive = rak_cam.readSerial();
    % disp(serial_receive)
    % length(this_audio)
end

if dev_mode
    brainless
end
