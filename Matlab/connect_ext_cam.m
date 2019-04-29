function ext_cam = connect_ext_cam(button_camera, ext_cam_id)

if ext_cam_id
    tic
    disp('Connecting external camera...')
    delete(imaqfind)
    imaqreset
    cam_info = imaqhwinfo('winvideo');
    ext_cam = videoinput('winvideo', ext_cam_id, cam_info.DeviceInfo(ext_cam_id).DefaultFormat);
    triggerconfig(ext_cam, 'manual');
    ext_cam.TriggerRepeat = Inf;
    ext_cam.FramesPerTrigger = 1;
    ext_cam.ReturnedColorspace = 'rgb'; 
    start(ext_cam)
    button_camera.BackgroundColor = [0.6 0.95 0.6];
    drawnow    
    disp(horzcat('External camera connected in ', num2str(round(toc)), ' seconds'))
    disp(horzcat('Format: ', cam_info.DeviceInfo(ext_cam_id).DefaultFormat))
else
    disp('External camera not selected')
    ext_cam = [];
end