if ~exist('rak_pulse', 'var') % Should probably check that the timer is running as well but apparently not straightforward?
    [rak_cam, rak_cam_h, rak_cam_w] = connect_rak(button_camera, use_webcam, text_title, text_load, button_bluetooth, popup_select_brain, brain_edit_name, button_startup_complete, camera_present, bluetooth_present, rak_only, button_exercises); 
%     ext_cam = connect_ext_cam(button_camera, ext_cam_id)
else
    disp('Already connected to RAK. rak_pulse timer is running.')
end

% this is needed somewhere? strcmp(rak_pulse.Running, 'on')