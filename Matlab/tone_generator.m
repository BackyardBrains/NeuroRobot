Fs = 8192;                          % Default Sampling Frequency (Hz)
Ts = 1/Fs;                          % Sampling Interval (s)
T = 0:Ts:(Fs*Ts);                   % One Second
Frq = 1000;                         % Tone Frequency
Y = sin(2*pi*Frq*T);                % Tone
Y0 = zeros(1, Fs*2);                % Silent Interval
Ys = [repmat([Y Y0], 1, 4) Y];      % Full Tone With Silent Intervals
soundsc(Ys,Fs);                     % Play Sound