
%% Check and display connection status

if sum(select_robot.Value == [1 2]) && exist('rak_cam', 'var') && (isa(rak_cam, 'NeuroRobot_matlab')) && rak_cam.isRunning()
    this_col = [0.6 0.95 0.6];
elseif sum(select_robot.Value == 3) && exist('rak_cam', 'var') && isa(rak_cam,'ipcam') && exist('esp32WebsocketClient', 'var') && isa(esp32WebsocketClient, 'ESP32SocketClient') && esp32WebsocketClient.Status()
    this_col = [0.6 0.95 0.6]; 
elseif sum(select_robot.Value == 4) && exist('rak_cam', 'var') && isa(rak_cam, 'webcam')
    this_col = [0.6 0.95 0.6];
elseif sum(select_robot.Value == 5) && exist('rak_cam', 'var')
    this_col = [0.6 0.95 0.6];
elseif sum(select_robot.Value == 6) && exist('rak_cam', 'var') && isa(rak_cam,'ipcam') && exist('esp32WebsocketClient', 'var') && isa(esp32WebsocketClient, 'ESP32SocketClient') && esp32WebsocketClient.Status() && isa(ext_cam, 'webcam')
    this_col = [0.6 0.95 0.6];    
else
    this_col = [0.8 0.8 0.8];
end

button_camera.BackgroundColor = this_col;