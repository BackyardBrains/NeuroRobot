recObj = audiorecorder(44100, 16, 1);
recordblocking(recObj, 5);
play(recObj);
y = getaudiodata(recObj);
figure(1)
clf
plot(mean(y));
axis tight
title('Honey')
figure(2)
clf
p = pspectrum(y,44000,'spectrogram', 'FrequencyLimits',[0 20],'TimeResolution',0.01, 'OverlapPercent',0)