if ~exist('rak_cam', 'var') || use_webcam
    [rak_cam, rak_cam_h, rak_cam_w] = connect_rak(button_camera, use_webcam, text_title, text_load, button_bluetooth, popup_select_brain, brain_edit_name, button_startup_complete, camera_present, bluetooth_present, rak_only, button_exercises, gong);
elseif ~use_webcam && exist('rak_cam', 'var') && ~rak_cam.isRunning()
    disp('rak_cam exists but is not running')
elseif exist('rak_cam', 'var') && rak_cam.isRunning()
    disp('rak_cam exists and is running')
else
    disp('connect status not recognized')
end

if rak_only
    if exist('rak_pulse', 'var') % This needed here?: evalin('base','rak_pulse')
        stop(rak_pulse)
        delete(rak_pulse)
    end
    rak_pulse = timer('period', pulse_period, 'timerfcn', 'rak_pulse_code', 'stopfcn', 'disp("RAK pulse stopped")', 'executionmode', 'fixedrate');    
    start(rak_pulse)
end

