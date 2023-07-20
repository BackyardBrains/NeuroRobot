
% 1.    'SpikerBot RAK5206'
% 2.    'SpikerBot RAK5270'
% 3.    'SpikerBot ESP32'
% 4.    'Computer with webcam'
% 5.    'Computer without webcam'

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
    use_webcam = 1;
    hd_camera = 0;
    use_esp32 = 0;
elseif select_robot.Value == 5
    rak_only = 0;
    camera_present = 0;
    use_webcam = 0;
    hd_camera = 0;
    use_esp32 = 0;       
elseif select_robot.Value == 6    
    rak_only = 0;
    camera_present = 1;
    use_webcam = 1;
    hd_camera = 0;
    use_esp32 = 1;       
end
