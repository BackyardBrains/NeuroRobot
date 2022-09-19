
read_module

if use_esp32
    addpath('.\MatlabWebSocket\src\')
end
if ~exist('esp32WebsocketClient', 'var')
    esp32WebsocketClient = 0;
end

[rak_cam, rak_cam_h, rak_cam_w, esp32WebsocketClient] = connect_rak(button_camera, camera_present, use_webcam, text_title, button_startup_complete, rak_only, hd_camera, use_esp32, esp32WebsocketClient, button_to_library, button_to_sleep, button_to_quit, button_new_brain);

if exist('rak_pulse', 'var') && isvalid(rak_pulse)
    stop(rak_pulse)
    delete(rak_pulse)
end

rak_pulse = timer('period', pulse_period, 'timerfcn', 'rak_pulse_code', 'executionmode', 'fixedrate');
start(rak_pulse)
