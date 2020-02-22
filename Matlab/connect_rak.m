function [rak_cam, rak_cam_h, rak_cam_w] = connect_rak(button_camera, use_webcam, text_title, text_load, button_bluetooth, popup_select_brain, edit_name, button_startup_complete, camera_present, bluetooth_present, rak_only, button_exercises, gong, hd_camera)

tic
disp('Connecting camera...')
button_camera.BackgroundColor = [0.94 0.78 0.62];
text_title.String = 'Connecting...';
text_load.String = '';
set(button_bluetooth, 'enable', 'off')
set(popup_select_brain, 'visible', 'off')
set(edit_name, 'enable', 'off')
set(button_camera, 'enable', 'off')
set(button_startup_complete, 'enable', 'off')
% set(button_exercises, 'enable', 'off')
drawnow

try

    if rak_only
        if (~exist('NeuroRobot_MatlabBridge.mexw64', 'file') && ispc) || (~isfile('NeuroRobot_MatlabBridge.mexmaci64') && ismac)
            disp('Building mex')
            rak_mex_build
        end
        
        try % This cause may cause crash here as well??
            disp('check 1')
            rak_cam_base = evalin('base','rak_cam');
            disp('check 2')
            if rak_cam_base.isRunning()
                rak_cam_base.stop();
            end
            disp('check 3')
            clear rak_cam_base
            disp('Previous rak_cam cleared')
        catch
            disp('No previous rak_cam')
        end
        clear rak_cam
        rak_cam = NeuroRobot_matlab('192.168.100.1', '80');
        disp('rak_cam created')
        rak_cam.start();
        if ~rak_cam.isRunning()
            disp('rak_cam started but not running')
            if hd_camera
                rak_cam_h = 1080;
                rak_cam_w = 1920;
            else
                rak_cam_h = 720;
                rak_cam_w = 1280;                
            end
        else
            disp('rak_cam is running')
            rak_cam.writeSerial('d:121;d:221;d:321;d:421;d:521;d:621;')
            rak_cam_h = rak_cam.readVideoHeight();
            rak_cam_w = rak_cam.readVideoWidth();
        end
    elseif ~use_webcam
        url = 'rtsp://admin:admin@192.168.100.1/cam1/h264';
        rak_cam = HebiCam(url);
            rak_cam_h = 1280;
            rak_cam_w = 720;        
    elseif use_webcam
        % Webcam
        delete(imaqfind)
        rak_cam = videoinput('winvideo', 1);
        triggerconfig(rak_cam, 'manual');
        rak_cam.TriggerRepeat = Inf;
        rak_cam.FramesPerTrigger = 1;
        rak_cam.ReturnedColorspace = 'rgb';
        start(rak_cam)
        rak_cam_h = 1280;
        rak_cam_w = 720;  
    end

    button_camera.BackgroundColor = [0.6 0.95 0.6];
    drawnow
    disp(horzcat('rak_object connected in ', num2str(round(toc)), ' seconds'))

catch

    disp('error: rak_cam created but not running')
    button_camera.BackgroundColor = [1 0.5 0.5];
    if bluetooth_present && exist('life_timer', 'var')
        motor_command = [0 0 0 0 0];
        prev_motor_command = [0 0 0 0 0];
        bluetooth_send_motor_command
    end
    sound(flipud(gong), 8192 * 7)
    disp('solution 1: make sure you are connected to the correct wifi network')
    disp('solution 2: try the connect button again')
    disp('solution 3: restart matlab (be persistent)')
    disp('solution 4: restart matlab and the robot')
    
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
% set(button_exercises, 'enable', 'on')


