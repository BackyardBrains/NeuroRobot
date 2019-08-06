
if rak_only
    
    % Get audio data from RAK
    this_audio = double(rak_cam.readAudio());
    if isempty(this_audio) || length(this_audio) < 1000
        disp('no audio data received or audio data < 1000 samples')
        max_amp = 0;
        max_freq = 0;
    else
        
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
    audioAmp = [audioAmp max_amp];
    audioFreq = [audioFreq max_freq];
    this_end = length(audioMat);
    audio_max_freq = max_freq;
%     disp(horzcat('audio max freq = ', num2str(max_freq), ', amp = ', num2str(max_amp), ', start = ', num2str(this_start), ', end = ', num2str(this_end)))

end
