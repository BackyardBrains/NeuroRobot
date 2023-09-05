
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

if length(this_audio) >= round(mic_fs * pulse_period * 0.8) % Why this check? Try/catch instead
    x = this_audio;
    x(isnan(x)) = 0;        
    y = fft(x);
    z = abs(y).^2;
    z = z(1:audx)';
    sound_spectrum(:,nstep) = z;
end


