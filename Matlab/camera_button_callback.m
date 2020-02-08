if ~exist('rak_cam', 'var')
    [rak_cam, rak_cam_h, rak_cam_w] = connect_rak(button_camera, use_webcam, text_title, text_load, button_bluetooth, popup_select_brain, brain_edit_name, button_startup_complete, camera_present, bluetooth_present, rak_only, button_exercises, gong);
elseif exist('rak_cam', 'var') && ~rak_cam.isRunning()
    disp('rak_cam exists but is not running')
else
    disp('rak_cam exists and is running')
end
disp('deleting previous rak_pulse')
if exist('rak_pulse', 'var')
    delete(rak_pulse)
end

% This could probably be conditional on this: exist('rak_cam', 'var') && ~rak_cam.isRunning()
disp('creating new rak_pulse')
rak_pulse_n = 0;
rak_pulse = timer('period', pulse_period, 'timerfcn', 'rak_pulse_code', 'stopfcn', 'disp("RAK pulse stopped")', 'executionmode', 'fixedrate');    
start(rak_pulse)   
