function [rak_cam, rak_cam_h, rak_cam_w, esp32WebsocketClient, ext_cam] = connect_rak(button_camera, camera_present, use_webcam, button_startup_complete, rak_only, hd_camera, use_esp32, esp32WebsocketClient, button_to_library, button_to_sleep, button_to_quit, button_new_brain)

connect_success = 0;

tic
disp('Connecting...')
button_camera.BackgroundColor = [0.94 0.78 0.62];
set(button_camera, 'enable', 'off')
set(button_startup_complete, 'enable', 'off')
set(button_to_library, 'enable', 'off')
set(button_to_sleep, 'enable', 'off')
set(button_to_quit, 'enable', 'off')
set(button_new_brain, 'enable', 'off')
drawnow

if rak_only
    try
        try
            rak_cam_base = evalin('base','rak_cam');
            if rak_cam_base.isRunning()
                rak_cam_base.stop();
            end
            clear rak_cam_base
            disp('Previous rak_cam cleared')
        catch
            disp('may23 connect_rak error')
        end
        clear rak_cam
        disp('Attempting RAK connect...')
        rak_cam = NeuroRobot_matlab('192.168.100.1', '80');
        disp('rak_cam created')

        rak_cam.start();
        if ~rak_cam.isRunning()
            disp('rak_cam created but not running')
            if hd_camera
                rak_cam_h = 1080;
                rak_cam_w = 1920;
            else
                rak_cam_h = 720;
                rak_cam_w = 1280;                
            end
        else
            disp('rak_cam is running')
            rak_cam.writeSerial('d:121;d:221;d:321;d:421;d:521;d:621;')
            rak_cam_h = rak_cam.readVideoHeight();
            rak_cam_w = rak_cam.readVideoWidth();
            connect_success = 1;
        end
    catch exception
        disp('rak connect failed')
        this_error = exception.message;
        msgbox(this_error)
    end
end

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
        
        url = 'http://192.168.4.1:81/stream';%robot is AP
        %url = 'http://192.168.0.14:81/stream';%use local AP
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
        esp32WebsocketClient = ESP32SocketClient('ws://192.168.4.1/ws');%robot is AP
        %esp32WebsocketClient = ESP32SocketClient('ws://192.168.0.14/ws');%use local AP
        esp32WebsocketClient.send('d:121;d:221;d:321;d:421;d:521;d:621;');

        connect_success = 1;

    catch
        disp('ESP32 connect FAILED')
    end
end

if use_webcam && ~(rak_only || use_esp32)
    disp('Attempting webcam connect...')
    try
        delete(imaqfind) % <<<< COMMENTED OUT FOR COMPILATION
        if ispc
            rak_cam = videoinput('winvideo', 1); % <<<< COMMENTED OUT FOR COMPILATION
        elseif ismac
            rak_cam = videoinput('macvideo', 1); % <<<< COMMENTED OUT FOR COMPILATION
        else
            disp('Unknown OS. Webcam not found.')
        end
    catch
        error('Unable to connect to Webcamera. Plut it in. Install Image Acquisition Support Package for Generic OS Interface.')
    end
    triggerconfig(rak_cam, 'manual'); % <<<< COMMENTED OUT FOR COMPILATION
    rak_cam.TriggerRepeat = Inf;
    rak_cam.FramesPerTrigger = 1;
    rak_cam.ReturnedColorspace = 'rgb';
    start(rak_cam) % <<<< COMMENTED OUT FOR COMPILATION
    trigger(rak_cam) % <<<< COMMENTED OUT FOR COMPILATION
    large_frame = getdata(rak_cam, 1); % <<<< COMMENTED OUT FOR COMPILATION       
    [rak_cam_h, rak_cam_w, ~] = size(large_frame);
    connect_success = 1;
end

if rak_only && (use_webcam || use_esp32)
    disp('Attempting webcam connect...')
    try
        delete(imaqfind) % <<<< COMMENTED OUT FOR COMPILATION
        if ispc
            ext_cam = videoinput('winvideo', 1); % <<<< COMMENTED OUT FOR COMPILATION
        elseif ismac
            ext_cam = videoinput('macvideo', 1); % <<<< COMMENTED OUT FOR COMPILATION
        else
            disp('Unknown OS. Webcam not found.')
        end
    catch
        error('Unable to connect to Webcamera. Plut it in. Install Image Acquisition Support Package for Generic OS Interface.')
    end
    triggerconfig(ext_cam, 'manual'); % <<<< COMMENTED OUT FOR COMPILATION
    ext_cam.TriggerRepeat = Inf;
    ext_cam.FramesPerTrigger = 1;
    ext_cam.ReturnedColorspace = 'rgb';
    start(ext_cam) % <<<< COMMENTED OUT FOR COMPILATION
    trigger(ext_cam) % <<<< COMMENTED OUT FOR COMPILATION
    ext_frame = getdata(ext_cam, 1); % <<<< COMMENTED OUT FOR COMPILATION       
else
    ext_cam = 0;
end

if connect_success
    button_camera.BackgroundColor = [0.6 0.95 0.6];
    drawnow
    disp(horzcat('Camera connected in ', num2str(round(toc)), ' s'))
elseif ~camera_present
    button_camera.BackgroundColor = [0.6 0.95 0.6];
    drawnow
    rak_cam = 0;
    rak_cam_h = 1;
    rak_cam_w = 1;     
    disp(horzcat('Blind connection created'))  
else
    disp('error: rak_cam created but not running')
    button_camera.BackgroundColor = [1 0.5 0.5];
    disp('Are you connected to your robots WiFi? Try restarting')
end

set(button_camera, 'enable', 'on')
set(button_startup_complete, 'enable', 'on')
set(button_to_library, 'enable', 'off')
set(button_to_sleep, 'enable', 'on')
set(button_to_quit, 'enable', 'on')
set(button_new_brain, 'enable', 'on')
