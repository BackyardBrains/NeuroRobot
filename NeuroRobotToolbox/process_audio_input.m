
if rak_only && hd_camera
    this_audio = double(rak_cam.readAudio());
elseif matlab_audio_rec
    this_audio = mic_obj();
    if use_extra
        tableOut = speech2text(speechObject, this_audio, mic_fs);
    end
end

if ~isempty(this_audio) && length(this_audio) >= 1000

    x = this_audio(1:1000);
    x(isnan(x)) = 0;        
    y = fft(x);
    z = abs(y).^2;
    z = z(1:audx)';

    if r_torque || l_torque
        robot_moving = 8;
    else
        if exist('robot_moving', 'var') && robot_moving
            robot_moving = robot_moving - 1;
        else
            sound_spectrum(:,nstep) = z;
        end
    end        
else
    disp('this_audio is empty or short')
end


