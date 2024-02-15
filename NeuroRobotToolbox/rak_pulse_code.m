
if use_esp32
    large_frame = snapshot(rak_cam);
    esp_get_serial
elseif use_webcam
    % large_frame = snapshot(rak_cam);
elseif rak_only
    large_frame = rak_cam.readVideo();
    large_frame = permute(reshape(large_frame, 3, rak_cam.readVideoWidth(), rak_cam.readVideoHeight()),[3,2,1]);
    this_audio = double(rak_cam.readAudio());
    serial_receive = rak_cam.readSerial();
end

% disp(serial_receive)