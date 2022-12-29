
if isdeployed && select_robot.Value == 6
    button_camera.BackgroundColor = [1 0.25 0.25];
    pause(0.75)
    button_camera.BackgroundColor = [0.8 0.8 0.8];
else

% 1.    'SpikerBot RAK5206'
% 2.    'SpikerBot RAK5270'
% 3.    'SpikerBot ESP32'
% 4.    'Eyeball ESP32 (positional)'
% 5.    'Eyeball ESP32 (continuous)'
% 6.    'Computer without Webcam'
% 7.    'Computer with Webcam'
% 8.    'SpikerBot RAK5206 + Webcam'

    if select_robot.Value == 1
        rak_only = 1;
        camera_present = 1;
        use_webcam = 0;
        hd_camera = 0;
        use_esp32 = 0;
    elseif select_robot.Value == 2
        rak_only = 1;
        camera_present = 1;
        use_webcam = 0;
        hd_camera = 1;
        use_esp32 = 0;
    elseif select_robot.Value == 3
        rak_only = 0;
        camera_present = 1;
        use_webcam = 0;
        hd_camera = 0;
        use_esp32 = 1;
    elseif select_robot.Value == 4
        rak_only = 0;
        camera_present = 1;
        use_webcam = 0;
        hd_camera = 0;
        use_esp32 = 1;        
    elseif select_robot.Value == 5
        rak_only = 0;
        camera_present = 1;
        use_webcam = 0;
        hd_camera = 0;
        use_esp32 = 1;        
    elseif select_robot.Value == 6
        rak_only = 0;
        camera_present = 0;
        use_webcam = 0;
        hd_camera = 0;
        use_esp32 = 0;
    elseif select_robot.Value == 7
        rak_only = 0;
        camera_present = 1;
        use_webcam = 1;
        hd_camera = 0;
        use_esp32 = 0;  
    elseif select_robot.Value == 8
        rak_only = 1;
        camera_present = 1;
        use_webcam = 1;
        hd_camera = 0;
        use_esp32 = 0;         
    end
    
    if use_esp32 && ~isdeployed
        addpath('.\MatlabWebSocket\src\')
    end
    if ~exist('esp32WebsocketClient', 'var')
        esp32WebsocketClient = 0;
    end
    
    [rak_cam, rak_cam_h, rak_cam_w, esp32WebsocketClient, ext_cam] = connect_rak(button_camera, camera_present, use_webcam, button_startup_complete, rak_only, hd_camera, use_esp32, esp32WebsocketClient, button_to_library, button_to_sleep, button_to_quit, button_new_brain);
    
    if select_robot.Value == 4 || select_robot.Value == 5
        clear arduino_obj
        arduino_obj = arduino();
        servo_obj = servo(arduino_obj, 'D10');
    end
    
    if exist('rak_pulse', 'var') && isvalid(rak_pulse)
        stop(rak_pulse)
        delete(rak_pulse)
    end
    
    rak_pulse = timer('period', pulse_period, 'timerfcn', 'rak_pulse_code', 'executionmode', 'fixedrate');
    start(rak_pulse)

end