
if rak_only
    
    % Get audio data from RAK
    this_audio = double(rak_cam.readAudio());
    if isempty(this_audio)
        disp('audio data empty')
        audio_step = [audio_step; 0 xstep];
        
        % rak_cam.readAudio sometimes returns an empty this_audio, but
        % somehow then returns a full this_audio in the same step. if a
        % full audio array is not eventally returned the RAK has to be
        % reset (rak_fail = 1);
        audio_empty_flag = audio_empty_flag + 1;
        if audio_empty_flag >= 3
            disp('repeating audio input failure, stopping')
            run_button = 4;
        end
        
    elseif length(this_audio) < 1000
        error('audio data < 1000 samples')
    elseif length(this_audio) > 1000
        disp('audio data > 1000 samples')
        audio_step = [audio_step; 2 xstep];
        this_audio = [];
        
    else
        
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
        [max_amp, j] = max(pw(101:500));
        max_freq = fx(j + 100);
        
    end
    
    this_start = length(audioMat);
    audioMat = [audioMat this_audio];
    audio_step = [audio_step; 1 xstep];
    this_end = length(audioMat);
    audio_max_freq = max_freq;
%     disp(horzcat('audio max freq = ', num2str(max_freq), ', amp = ', num2str(max_amp), ', start = ', num2str(this_start), ', end = ', num2str(this_end)))

end
