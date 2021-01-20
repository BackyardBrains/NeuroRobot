
if rak_only % If RAK robot

    this_audio = double(rak_cam.readAudio());

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
    
else % If webcam-mode
    
    if matlab_audio_rec
                
        recordblocking(audio_recObj,0.1)
        this_audio = getaudiodata(audio_recObj);       
        n_audio_segments = 0;
        multi_sound_spectrum = zeros(audx, 1);
        if length(this_audio) >= 1000
            n_audio_segments = floor(length(this_audio)/1000);
            multi_sound_spectrum = zeros(audx, n_audio_segments);
            for n_audio_segment = 1:n_audio_segments
                x = this_audio((1:1000) + ((n_audio_segment - 1) * 1000));
                
                % Get spectrum
                x(isnan(x)) = 0;        
                fs = 16000;
                y = fft(x);
                z = (abs(y).^2)/fs;
                if ~isempty(z)
                    multi_sound_spectrum(:,n_audio_segment) = z(1:audx);
                end
                
            end
        
        end

        if n_audio_segments > 1
            z = max(multi_sound_spectrum, [], 2);
        else
            z = multi_sound_spectrum;
        end
        
        sound_spectrum(:,nstep) = z(1:audx);        
    end
end

