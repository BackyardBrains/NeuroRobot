
if exist('dev_mode', 'var') && ~dev_mode

    if use_esp32
        large_frame = snapshot(rak_cam);
        large_frame = imrotate(large_frame, 270);        
        get_esp_serial
    else
        large_frame = rak_cam.readVideo();
        large_frame = permute(reshape(large_frame, 3, rak_cam.readVideoWidth(), rak_cam.readVideoHeight()),[3,2,1]);
        this_audio = double(rak_cam.readAudio());
        serial_receive = rak_cam.readSerial();
        % disp(serial_receive)
        % length(this_audio)
    end

elseif exist('dev_mode', 'var') && dev_mode

    if use_esp32
        large_frame = snapshot(rak_cam);
        large_frame = imrotate(large_frame, 270);        
        get_esp_serial
    else
        large_frame = rak_cam.readVideo();
        large_frame = permute(reshape(large_frame, 3, rak_cam.readVideoWidth(), rak_cam.readVideoHeight()),[3,2,1]);
        this_audio = double(rak_cam.readAudio());
        serial_receive = rak_cam.readSerial();
        % disp(serial_receive)
        % length(this_audio)
    end

    brainless

end