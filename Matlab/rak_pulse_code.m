
% Keep RAK alive

rak_cam.writeSerial('l:0;r:0;s:0;')
large_frame = rak_cam.readVideo();
large_frame = permute(reshape(large_frame, 3, rak_cam.readVideoWidth(), rak_cam.readVideoHeight()),[3,2,1]);
this_audio = double(rak_cam.readAudio());
serial_receive = rak_cam.readSerial();
rak_pulse_n = rak_pulse_n + 1;
if ~rem(rak_pulse_n, 100)
% disp(horzcat('RAK pulse, n = ', num2str(rak_pulse_n)))
end