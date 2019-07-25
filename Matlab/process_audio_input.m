
if rak_only
    
    this_audio = double(rak_cam.readAudio());
    
    sample_rate = 8000;
    sample_period = 1/sample_rate;
    t = (0:sample_period:(length(this_audio)-1)/sample_rate);

    m = length(this_audio);
    n = pow2(nextpow2(m));
    y = fft(this_audio, n);
    f = (0:n-1)*(sample_rate/n);
    amplitude = abs(y)/n;
    
%     amplitude = amplitude(1:floor(n/2));
%     f = f(1:floor(n/2));
    
    [max_amp, j] = max(amplitude);
    max_freq = f(j);
    
    this_start = length(audioMat);
    
    audioMat = [audioMat this_audio];
    audioAmp = [audioAmp max_amp];
    audioFreq = [audioFreq max_freq];
    
    this_end = length(audioMat);
    
    audio_max_freq = max_freq;
    disp(horzcat('audio max freq = ', num2str(max_freq), ', amp = ', num2str(max_amp), ', start = ', num2str(this_start), ', end = ', num2str(this_end)))
    
    
end

%%

%     this_audio = audioMat(374001:375000);
%     sample_rate = 8000;
%     sample_period = 1/sample_rate;
%     t = (0:sample_period:(length(this_audio)-1)/sample_rate);
% 
%     m = length(this_audio);
%     n = pow2(nextpow2(m));
%     y = fft(this_audio, n);
%     f = (0:n-1)*(sample_rate/n);
%     amplitude = abs(y)/n;
%     
% %     amplitude = amplitude(1:floor(n/2));
% %     f = f(1:floor(n/2));
%     
%     [max_amp, j] = max(amplitude);
%     max_freq = f(j);
%     
% figure(10); clf; plot(f, amplitude)