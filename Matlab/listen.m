% a.  Plot the signal in time and the amplitude of its frequency 
% components using the FFT.

[sample_data, sample_rate] = audioread('test.wav');

% sample_data = audioMatDouble;
% sample_rate = 8000;

sample_period = 1/sample_rate;
t = (0:sample_period:(length(sample_data)-1)/sample_rate);
subplot(2,2,1)
plot(t,sample_data)
title('Time Domain Representation - Unfiltered Sound')
xlabel('Time (seconds)')
ylabel('Amplitude')
xlim([0 t(end)])

m = length(sample_data); % Original sample length.
n = pow2(nextpow2(m)); % Transforming the length so that the number of 
% samples is a power of 2. This can make the transform computation 
% significantly faster,particularly for sample sizes with large prime 
% factors.
y = fft(sample_data, n);
f = (0:n-1)*(sample_rate/n);
amplitude = abs(y)/n;
subplot(2,2,2)
plot(f(1:floor(n/2)),amplitude(1:floor(n/2)))
title('Frequency Domain Representation - Unfiltered Sound')
xlabel('Frequency')
ylabel('Amplitude')

%%2)  Filter the audio sample data to remove noise from the signal.
order = 7;
[b,a] = butter(order,1000/(sample_rate/2),'low');
% filtered_sound = filter(b,a,sample_data);


%%%%
Fs = sample_rate;                                       % Sampling Frequency (Hz)
Fn = Fs/2;                                              % Nyquist Frequency (Hz)
Wp = 1000/Fn;                                           % Passband Frequency (Normalised)
Ws = 1010/Fn;                                           % Stopband Frequency (Normalised)
Rp =   1;                                               % Passband Ripple (dB)
Rs = 150;                                               % Stopband Ripple (dB)
[n,Ws] = cheb2ord(Wp,Ws,Rp,Rs);                         % Filter Order
[z,p,k] = cheby2(n,Rs,Ws,'low');                        % Filter Design
[soslp,glp] = zp2sos(z,p,k);                            % Convert To Second-Order-Section For Stability
figure(3)
freqz(soslp, 2^16, Fs)                                  % Filter Bode Plot
filtered_sound = filtfilt(soslp, glp, sample_data);
sound(filtered_sound, sample_rate)
%%%%

t1 = (0:sample_period:(length(filtered_sound)-1)/sample_rate);
subplot(2,2,3)
plot(t1,filtered_sound)
title('Time Domain Representation - Filtered Sound')
xlabel('Time (seconds)')
ylabel('Amplitude')
xlim([0 t1(end)])
m1 = length(sample_data); % Original sample length.
n1 = pow2(nextpow2(m1)); % Transforming the length so that the number of 
% samples is a power of 2. This can make the transform computation 
% significantly faster,particularly for sample sizes with large prime 
% factors. 
y1 = fft(filtered_sound, n1);
f = (0:n1-1)*(sample_rate/n1);
amplitude = abs(y1)/n1;
subplot(2,2,4)
plot(f(1:floor(n1/2)),amplitude(1:floor(n1/2)))
title('Frequency Domain Representation - Filtered Sound')
xlabel('Frequency')
ylabel('Amplitude')

