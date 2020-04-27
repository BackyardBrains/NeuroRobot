
if rak_only
    
    % Get audio data from RAK
    this_audio = double(rak_cam.readAudio());

    if isempty(this_audio)
        this_clock = clock;
        audio_step = [audio_step; 0 xstep this_clock(6) length(this_audio)];
        max_freq = 0;
        max_amp = 0;
        
        % rak_cam.readAudio sometimes returns an empty this_audio, but
        % somehow then returns a full this_audio in the same step. if a
        % full audio array is not eventally returned the RAK has to be
        % reset (rak_fail = 1);
        audio_empty_flag = audio_empty_flag + 1;
    elseif length(this_audio) >= 500

        this_clock = clock;
        audio_step = [audio_step; 2 xstep this_clock(6) length(this_audio)];
        max_freq = 0;
        max_amp = 0;   
        
        if length(this_audio) < 1000
            this_audio = [this_audio this_audio];
        end
        if length(this_audio) >= 1000
            this_audio = this_audio(1:1000); % ***
        end
        if xstep == 1
            this_audio = zeros(1, 1000);
        end
        audio_empty_flag = 0;
        
        this_audio(1:100) = 0; %% <<
        
        % Get first 1000 samples
        x = this_audio;

        % Get spectrum
        n = length(x); %%%% THIS IS NOT RIGHT 2020-03-14, I'm aware, e.g. this ***
        if hd_camera
            fs = 16000;
        else
            fs = 8000;
        end
        dt = 1/fs;
        t = (0:n-1)/fs;
        y = fft(x);
        pw = (abs(y).^2)/n;
        fx = (0:n-1)*(fs/n);
    
        % Convert to Z scores
        pw = (pw - mean(pw)) / std(pw);
        
        % Get amp and freq
%         [max_amp, j] = max(pw(1:250));
        [max_amp, j] = max(pw);
        max_freq = fx(j);
        
        this_clock = clock;
        audio_step = [audio_step; 1 xstep this_clock(6) length(this_audio)];        

    else
        
        if ~rem(nstep, 40)
            disp(horzcat('this_audio has unexpected length (showing 1 of 40 errors)'))
            disp(horzcat('= ', num2str(length(this_audio))))
        end        
        this_clock = clock;
        audio_step = [audio_step; 0 xstep this_clock(6) length(this_audio)];
        max_freq = 0;
        max_amp = 0;
    end
    
    audio_max_freq = max_freq;

else % Implement audio toolbox record here 
    
    this_audio = zeros(1, 1000);
    
end
