
if rak_only
    
%     this_audio = rak_cam.readAudio();
    this_audio = audioMatDouble(140001:170000);
    
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
    
    audioMat = [audioMat this_audio];
    audioAmp = [audioAmp max_amp];
    audioFreq = [audioFreq max_freq];
    
end