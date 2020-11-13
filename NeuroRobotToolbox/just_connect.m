
clear rak_cam
rak_cam = NeuroRobot_matlab('192.168.100.1', '80');
% rak_cam = NeuroRobot_matlab('10.0.0.1', '80');
rak_cam.start();
if rak_cam.isRunning()
    disp('rak_cam is running')
    rak_cam.writeSerial('d:121;d:221;d:321;d:421;d:521;d:621;')
else
    disp('rak_cam created but not running')
end
