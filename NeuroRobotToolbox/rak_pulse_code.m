
if exist('dev_mode', 'var') && ~dev_mode

    % Keep RAK alive

    large_frame = rak_cam.readVideo();
    large_frame = permute(reshape(large_frame, 3, rak_cam.readVideoWidth(), rak_cam.readVideoHeight()),[3,2,1]);
    this_audio = double(rak_cam.readAudio());
    serial_receive = rak_cam.readSerial();
    % disp(serial_receive)
    % length(this_audio)

elseif exist('dev_mode', 'var') && dev_mode

    large_frame = rak_cam.readVideo();
    large_frame = permute(reshape(large_frame, 3, rak_cam.readVideoWidth(), rak_cam.readVideoHeight()),[3,2,1]);
    this_audio = double(rak_cam.readAudio());
    serial_receive = rak_cam.readSerial();

    brainless

end