function [rak_cam, rak_cam_h, rak_cam_w, esp32WebsocketClient, ext_cam, ext_cam_h, ext_cam_w] = connect_rak(button_camera, camera_present, use_webcam, button_startup_complete, rak_only, hd_camera, use_esp32, esp32WebsocketClient, button_to_simulator, button_to_sleep, button_to_quit, button_new_brain)

connect_success = 0;

tic
disp('Connecting...')
button_camera.BackgroundColor = [0.94 0.78 0.62];
set(button_camera, 'enable', 'off')
set(button_startup_complete, 'enable', 'off')
set(button_to_simulator, 'enable', 'off')
set(button_to_sleep, 'enable', 'off')
set(button_to_quit, 'enable', 'off')
set(button_new_brain, 'enable', 'off')
drawnow

if use_esp32
    try
        rak_cam = evalin('base','rak_cam');
    catch
        rak_cam = 0;
    end
    if(isa(rak_cam,'ipcam'))
        evalin('base','clear rak_cam');
        disp('delete rak cam')
    end

    disp('Attempting ESP32 connect...')
    try
        clear rak_cam
        
        url = 'http://192.168.4.1:81/stream';
        rak_cam = ipcam(url);
        rak_cam_h = 240;
        rak_cam_w = 320;   
        
        if(isa(esp32WebsocketClient,'ESP32SocketClient'))
            if esp32WebsocketClient.Status
                esp32WebsocketClient.close();
            end
            esp32WebsocketClient.delete();
            evalin('base','clear esp32WebsocketClient');
        end
        esp32WebsocketClient = ESP32SocketClient('ws://192.168.4.1/ws');
        just_orange

        connect_success = 1;

    catch
        disp('ESP32 connect FAILED')
    end
end

if use_webcam && ~use_esp32
    disp('Attempting webcam connect...')
    try
        rak_cam = webcam;
    catch
        error('Cannot connect webcam')
    end
    large_frame = snapshot(rak_cam);   
    [rak_cam_h, rak_cam_w, ~] = size(large_frame);
    connect_success = 1;
end

if use_webcam && use_esp32
    disp('Attempting ext webcam connect...')
    try
        ext_cam = webcam;
    catch
        error('Cannot connect ext webcam')
    end
    ext_frame = snapshot(ext_cam);   
    [ext_cam_h, ext_cam_w, ~] = size(ext_frame);
    connect_success = 1;
else
    ext_cam = 0;
    ext_cam_h = 0;
    ext_cam_w = 0;
end

if connect_success
    button_camera.BackgroundColor = [0.6 0.95 0.6];
    drawnow
    disp(horzcat('Camera connected in ', num2str(round(toc)), ' s'))
elseif ~camera_present
    button_camera.BackgroundColor = [0.6 0.95 0.6];
    drawnow
    rak_cam = 0;
    rak_cam_h = 240;
    rak_cam_w = 320;     
    disp(horzcat('Blind connection created'))  
else
    disp('error: rak_cam created but not running')
    button_camera.BackgroundColor = [1 0.5 0.5];
    disp('Are you connected to your robots WiFi? Try restarting')
end

set(button_camera, 'enable', 'on')
set(button_startup_complete, 'enable', 'on')
set(button_to_simulator, 'enable', 'on')
set(button_to_sleep, 'enable', 'on')
set(button_to_quit, 'enable', 'on')
set(button_new_brain, 'enable', 'on')
