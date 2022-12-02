rak_fail = 0;
try
    if rak_only && ~use_webcam
        large_frame = rak_cam.readVideo();
        large_frame = permute(reshape(large_frame, 3, rak_cam.readVideoWidth(), rak_cam.readVideoHeight()),[3,2,1]);
    elseif use_esp32 && ~use_webcam
        large_frame = snapshot(rak_cam);
    elseif use_webcam && ~(rak_only || use_esp32)
        trigger(rak_cam)
        large_frame = getdata(rak_cam, 1);
    elseif use_webcam && (rak_only || use_esp32)
        if rak_only 
            large_frame = rak_cam.readVideo();
            large_frame = permute(reshape(large_frame, 3, rak_cam.readVideoWidth(), rak_cam.readVideoHeight()),[3,2,1]);            
        elseif use_esp32
            large_frame = snapshot(rak_cam);
        end
    else
        large_frame = zeros(rak_cam_h, rak_cam_w, 3, 'uint8');
    end
    if night_vision
        large_frame = histeq(large_frame, 64*4);
    end
catch
    large_frame = zeros(rak_cam_h, rak_cam_w, 3, 'uint8');
    disp('RAK fail')
    rak_fail = 1;
end