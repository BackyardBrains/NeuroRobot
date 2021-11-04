[rak_cam, rak_cam_h, rak_cam_w, esp32WebsocketClient] = connect_rak(button_camera, use_webcam, text_title, text_load, button_bluetooth, popup_select_brain, brain_edit_name, button_startup_complete, camera_present, bluetooth_present, rak_only, gong, hd_camera, use_esp32, esp32WebsocketClient);

if rak_only
    if exist('rak_pulse', 'var') && isvalid(rak_pulse)
        stop(rak_pulse)
        delete(rak_pulse)
    end
    
    rak_pulse = timer('period', pulse_period, 'timerfcn', 'rak_pulse_code', 'stopfcn', 'disp("RAK pulse stopped")', 'executionmode', 'fixedrate');
    start(rak_pulse)
    
    if ~use_webcam && exist('rak_cam', 'var') && (isa(rak_cam, 'NeuroRobot_matlab')) && rak_cam.isRunning()
        set(button_camera, 'BackgroundColor', [0.6 0.95 0.6], 'enable', 'off')
    end
    
end

