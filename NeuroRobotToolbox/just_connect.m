
clear rak_cam

rak_cam = NeuroRobot_matlab('192.168.100.1', '80');
% rak_cam = NeuroRobot_matlab('10.0.0.1', '80');

rak_cam.start();

if rak_cam.isRunning()
    disp('rak_cam is running')
    pause(0.1)
    rak_cam.writeSerial('d:121;d:221;d:321;d:421;d:521;d:621;')
    rak_cam_h = rak_cam.readVideoHeight();
    rak_cam_w = rak_cam.readVideoWidth();
else
    disp('rak_cam created but not running')
end
