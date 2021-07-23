clear rak_cam
rak_cam = NeuroRobot_matlab('192.168.100.1', '80');


rak_cam.start();
rak_cam.isRunning()