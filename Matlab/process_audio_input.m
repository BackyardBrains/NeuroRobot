
if rak_only
    
    % Get audio data from RAK
    this_audio = double(rak_cam.readAudio());
%     disp(num2str(length(this_audio)))

    if isempty(this_audio)
        max_freq = 0;
        max_amp = 0;
        
        % rak_cam.readAudio sometimes returns an empty this_audio, but
        % somehow then returns a full this_audio in the same step. if a
        % full audio array is not eventally returned the RAK has to be
        % reset (rak_fail = 1);
        audio_empty_flag = audio_empty_flag + 1;
    elseif length(this_audio) >= 500

        max_freq = 0;
        max_amp = 0;   
        
        if length(this_audio) < 1000
            this_audio = [this_audio this_audio];
        end
        if length(this_audio) >= 1000
            this_audio = this_audio(1:1000);
        end
        if xstep == 1
            this_audio = zeros(1, 1000);
        end
        audio_empty_flag = 0;

        % Get spectrum
        x = this_audio;
        x(isnan(x)) = 0;        
        n = length(x);
        if hd_camera
            fs = 32000;
            dt = 1/fs;
            t = (0:n-1)/fs;
            y = fft(x);
            pw = (abs(y).^2)/fs;
        else
            fs = 8000;
            dt = 1/fs;
            t = (0:n-1)/fs;
            y = fft(x);
            pw = (abs(y).^2)/n;          
        end
        pw = (pw - mean(pw)) / std(pw);   
        pw(1:10) = 0;
        [max_amp, j] = max(pw(1:audx));
        fx = linspace(0, 2000, audx);
        max_freq = fx(j);
        disp(num2str(max_freq))
        
    else
        
        if ~rem(nstep, 40)
            disp(horzcat('this_audio has unexpected length (showing 1 of 40 errors)'))
            disp(horzcat('= ', num2str(length(this_audio))))
        end        
        max_freq = 0;
        max_amp = 0;
    end
    
    audio_max_freq = max_freq;

else % Implement audio toolbox record here 
    
    this_audio = zeros(1, 1000);
    
end
