
load('C:\Users\Christopher Harris\NeuroRobot\Matlab\Data\2019-08-08-11-35-06-356-Scan')

audio = data.audio;
audio_hz = 8000;
audio_dur_in_sec = length(audio) / audio_hz;
disp(horzcat('Audio duration = ', num2str(audio_dur_in_sec), ' s'))
firing = data.firing;
firing_hz = 8;
firing_dur_in_sec = length(firing) / firing_hz;
disp(horzcat('Firing duration = ', num2str(firing_dur_in_sec), ' s'))


%%
fig1 = figure(1);
clf

subplot(2,1,1)
% plot(audio)
[p, f, t] = pspectrum(audio, audio_hz, 'spectrogram', 'frequencylimits', [1000 3000], 'timeresolution', 0.1, 'overlappercent', 0);
power_8000 = mean(p(f > 1900 & f < 2100, :));
plot(0.1:0.1:audio_dur_in_sec, power_8000)

subplot(2,1,2)
plot(firing(1,:))




%%
for ii = 1:length(data.audio_step(:,1))
    a = data.audio_step(ii, 1);
    b = data.audio_step(ii, 2);
    if a == 0
        c = data.audio_step(ii + 1, 2);
        if c == b
            disp('No problem')
        else
            error('Problem')
        end
    end
end
