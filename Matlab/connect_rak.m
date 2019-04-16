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
        if ~exist('RAK5206.mexw64', 'var')
            if strcmp(computer_name, 'laptop-main') % If Chris' laptop, use his mex settings
                mex RAK5206.cpp -IC:\boost_1_68_0 -LC:\boost_1_68_0\stage\lib -LC:\ffmpeg-4.1-win64-dev\lib -IC:\ffmpeg-4.1-win64-dev\include -lavcodec -lavformat -lavutil -lswscale -llibboost_system-vc141-mt-x64-1_68 -llibboost_chrono-vc141-mt-x64-1_68 -D_WIN32_WINNT=0x0A00
            else % else use Djordje's settings
                mex RAK5206.cpp -IC:\boost_1_69_0 -LC:\boost_1_69_0\stage\lib -LC:\ffmpeg-4.1.1-win64-dev\lib -IC:\ffmpeg-4.1.1-win64-dev\include -lavcodec -lavformat -lavutil -lswscale -llibboost_system-vc141-mt-x64-1_69 -llibboost_chrono-vc141-mt-x64-1_69 -D_WIN32_WINNT=0x0A00
            end
        end
        disp('Mex done')
        rak_cam = RAK5206_matlab('192.168.100.1', '80');
        disp('Rak_cam created')
    elseif ~use_webcam
        % RAK
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

    disp('RAK connection failed. Is your WiFi connected to the correct SSID ("LTH...")?')
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

if rak_only && exist('rak_cam', 'var')
    disp('Trying to start cam')
    rak_cam.start();
    disp('Cam started')
end
