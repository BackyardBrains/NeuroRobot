% New restart code
if exist('brain_name.mat', 'file')
    disp('Restarting...')
    load('brain_name')
	delete brain_name.mat
    for nbrain = 1:nbrains
        if strcmp(brain_name, available_brains(nbrain).name(1:end-4))
            nbrains = size(available_brains, 1);
            popup_select_brain.Value = nbrain + 1;
        end
    end    
    brain_edit_name.String = brain_name;      
    try
        [rak_cam, rak_cam_h, rak_cam_w, esp32WebsocketClient] = connect_rak(button_camera, use_webcam, text_title, text_load, button_bluetooth, popup_select_brain, brain_edit_name, button_startup_complete, camera_present, bluetooth_present, rak_only, hd_camera, use_esp32, esp32WebsocketClient);
        start(rak_pulse)
        disp('RAK reconnected')
        startup_complete
    catch
        if bluetooth_present
            set(button_bluetooth, 'enable', 'on')
        end
        set(popup_select_brain, 'visible', 'on')
        set(brain_edit_name, 'enable', 'on')
        if camera_present
            set(button_camera, 'enable', 'on')
        end
        set(button_startup_complete, 'enable', 'on')
        button_camera.BackgroundColor = [1 0.5 0.5];
        disp('Unable to reconnect to RAK')
    end    
end

% Manual restart code
if exist('restarting', 'var') && restarting
    for nbrain = 1:nbrains
        if strcmp(brain_name, available_brains(nbrain).name(1:end-4))
            nbrains = size(available_brains, 1);
            popup_select_brain.Value = nbrain + 1;
        end
    end    
    brain_edit_name.String = brain_name;
    restarting = 0;
    voluntary_restart = 0;
    startup_complete
end
