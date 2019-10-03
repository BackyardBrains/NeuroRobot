function [rak_cam, rak_pulse] = connect_rak(button_camera, pulse_period, use_webcam, text_title, text_load, button_bluetooth, popup_select_brain, edit_name, button_startup_complete, camera_present, bluetooth_present, rak_only)

tic
disp('Connecting camera...')
button_camera.BackgroundColor = [0.94 0.78 0.62];
text_title.String = 'Connecting camera...';
text_load.String = '';
set(button_bluetooth, 'enable', 'off')
set(popup_select_brain, 'visible', 'off')
set(edit_name, 'enable', 'off')
set(button_camera, 'enable', 'off')
set(button_startup_complete, 'enable', 'off')
drawnow


try

    if rak_only
        if ~exist('RAK_MatlabBridge.mexw64', 'file')
            disp('Building mex')
            rak_mex_build
        end
        if exist('rak_pulse', 'var')
            delete(rak_pulse)
            clear rak_pulse
            disp('Previous rak_pulse deleted')
        end
        if exist('rak_cam', 'var')
            clear rak_cam
            disp('Previous rak_cam cleared')
        end        
        rak_cam = RAK5206_matlab('192.168.100.1', '80');
        disp('rak_cam created')
        rak_cam.start();
        if ~rak_cam.isRunning()
            disp('rak_cam started but not running')
            error('rak_cam started but not running')
        else
            disp('rak_cam is running')
        end
    elseif ~use_webcam
        url = 'rtsp://admin:admin@192.168.100.1/cam1/h264';
        rak_cam = HebiCam(url);
    elseif use_webcam
        % Webcam
        rak_cam = videoinput('winvideo', 1);
        triggerconfig(rak_cam, 'manual');
        rak_cam.TriggerRepeat = Inf;
        rak_cam.FramesPerTrigger = 1;
        rak_cam.ReturnedColorspace = 'rgb';
        start(rak_cam)
    end

    % Pulse
    rak_pulse = timer('period', pulse_period, 'timerfcn', '[large_frame, rak_fail] = get_rak_frame(rak_cam, use_webcam, rak_only);', 'stopfcn', 'disp("RAK pulse stopped")', 'executionmode', 'fixedrate');
    button_camera.BackgroundColor = [0.6 0.95 0.6];
    drawnow
    disp(horzcat('RAK module connected in ', num2str(round(toc)), ' seconds'))

catch

    disp('RAK connection failed. Is your computer connected to the correct WiFi?')
    button_camera.BackgroundColor = [1 0.5 0.5];
    if bluetooth_present && exist('life_timer', 'var')
        motor_command = [0 0 0 0 0];
        prev_motor_command = [0 0 0 0 0];
        bluetooth_send_motor_command
    end
end

text_title.String = 'Neurorobot Startup';
text_load.String = 'Select brain';
if bluetooth_present
    set(button_bluetooth, 'enable', 'on')
end
set(popup_select_brain, 'visible', 'on')
set(edit_name, 'enable', 'on')
if camera_present
    set(button_camera, 'enable', 'on')
end
set(button_startup_complete, 'enable', 'on')
