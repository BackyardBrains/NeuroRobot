if isempty(imaqfind)
    if ~sum(select_robot.Value == 3) && exist('rak_cam', 'var') && (isa(rak_cam, 'NeuroRobot_matlab')) && rak_cam.isRunning()
        this_col = [0.6 0.95 0.6];
    elseif exist('rak_cam', 'var') && (isa(rak_cam, 'NeuroRobot_matlab')) && ~rak_cam.isRunning() 
        this_col = [1 0.5 0.5];
    elseif sum(select_robot.Value == 3) && exist('rak_cam', 'var') && isa(rak_cam,'ipcam') && exist('esp32WebsocketClient', 'var') && isa(esp32WebsocketClient, 'ESP32SocketClient') && esp32WebsocketClient.Status()
        this_col = [0.6 0.95 0.6];
    else
        this_col = [0.8 0.8 0.8];
    end
else
    this_col = [0.6 0.95 0.6];
end

button_camera.BackgroundColor = this_col;