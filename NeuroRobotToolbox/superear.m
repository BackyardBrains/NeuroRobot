
%% Mic setup
nsteps = 30;
ms_per_step = 100;
fs = 16000;
samples_per_step = fs / (1000 / ms_per_step);
mic_obj = audioDeviceReader('SampleRate', fs, 'SamplesPerFrame', samples_per_step); % ms per step should come in here
setup(mic_obj)

%% Mic test
mic_data = zeros(nsteps * samples_per_step, 1);
for nstep = 1:nsteps
    tic
    [this_audio, numoverrun] = record(mic_obj);
    mic_data(1 + ((nstep - 1) * samples_per_step) : samples_per_step * nstep) = this_audio;
end
figure(1)
clf
plot(mic_data)
sound(mic_data, fs)
