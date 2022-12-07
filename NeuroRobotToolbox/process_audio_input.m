
if rak_only && hd_camera
    this_audio = double(rak_cam.readAudio());
elseif matlab_audio_rec
    this_audio = mic_obj();
    if use_speech2text
        if ~isempty(this_audio)
            tableOut = speech2text(speechObject, this_audio, mic_fs);
            
        else
            disp('Warning: this_audio is empty, cannot complete speech2text')
        end
    end
end

% if ~isempty(this_audio) && length(this_audio) < 1000
%     while length(this_audio) < 1000
%         this_audio = [this_audio this_audio];
%     end
% end
    
% if ~isempty(this_audio) && length(this_audio) >= 500
if ~isempty(this_audio) && length(this_audio) >= 1000

%     x = this_audio(1:500);
    x = this_audio(1:1000);
    x(isnan(x)) = 0;        
    y = fft(x);
    z = abs(y).^2;
    z = z(1:audx)';

%     if ~robot_moving
        sound_spectrum(:,nstep) = z;
%     end
end


