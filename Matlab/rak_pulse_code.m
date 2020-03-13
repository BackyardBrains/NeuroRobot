
% Keep RAK alive

rak_cam.writeSerial('l:0;r:0;s:0;')
% rak_cam.writeSerial('l:50;r:50;s:0;')
% rak_cam.writeSerial('l:-50;r:-50;s:0;')

large_frame = rak_cam.readVideo();
large_frame = permute(reshape(large_frame, 3, rak_cam.readVideoWidth(), rak_cam.readVideoHeight()),[3,2,1]);
this_audio = double(rak_cam.readAudio());
serial_receive = rak_cam.readSerial();
