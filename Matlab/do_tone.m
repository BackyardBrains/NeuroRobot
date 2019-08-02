Fs = 8192;
Ts = 1/Fs;
T = 0:Ts:(Fs*Ts);
Frq = 1000;
Y = sin(2*pi*Frq*T);
Y0 = zeros(1, Fs * 2);
Ys = [repmat([Y Y0], 1, 9) Y];
% Ys = Y;

soundsc(Ys, Fs);