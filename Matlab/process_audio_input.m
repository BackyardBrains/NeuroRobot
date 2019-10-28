
if rak_only
    
    % Get audio data from RAK
    this_audio = double(rak_cam.readAudio());

    if isempty(this_audio)
        disp('audio data empty')
        this_clock = clock;
        audio_step = [audio_step; 0 xstep this_clock(6) length(this_audio)];
        max_freq = 0;
        max_amp = 0;
        
        % rak_cam.readAudio sometimes returns an empty this_audio, but
        % somehow then returns a full this_audio in the same step. if a
        % full audio array is not eventally returned the RAK has to be
        % reset (rak_fail = 1);
        audio_empty_flag = audio_empty_flag + 1;
%         if audio_empty_flag >= 100
%             disp('repeating audio input failure, stopping')
% %             run_button = 4;
%             stop(rak_pulse)
%             pause(0.5)
%             rak_fail = 1;
%         end
        
    elseif length(this_audio) < 1000
        error('audio data < 1000 samples')
    elseif length(this_audio) >= 1000
        if nstep == 1
            disp('audio data > 1000 samples')
        end
        this_clock = clock;
        audio_step = [audio_step; 2 xstep this_clock(6) length(this_audio)];
        max_freq = 0;
        max_amp = 0;     
        if xstep == 1
            this_audio = zeros(1, 1000);
        end
        audio_empty_flag = 0;
        
        
        % Get first 1000 samples
        x = this_audio(1:1000);

        % Get spectrum
        n = length(x);
        fs = 8000;
        dt = 1/fs;
        t = (0:n-1)/fs;
        y = fft(x);
        pw = (abs(y).^2)/n;
        fx = (0:n-1)*(fs/n);
    
        % Convert to Z scores
        pw = (pw - mean(pw)) / std(pw);
        
        % Get amp and freq
        [max_amp, j] = max(pw(1:250));
        max_freq = fx(j);
        
        this_clock = clock;
        audio_step = [audio_step; 1 xstep this_clock(6) length(this_audio)];        
        
    end
    
    audio_max_freq = max_freq;
%     disp(horzcat('audio max freq = ', num2str(round(max_freq)), ', amp = ', num2str(round(max_amp))))

else % Implement audio toolbox record here 
    
    this_audio = zeros(1, 1000);
    
end
