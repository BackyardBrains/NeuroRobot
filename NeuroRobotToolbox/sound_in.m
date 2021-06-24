

% recObj = audiorecorder(16000, 16, 1);

recordblocking(recObj, 2)
data = getaudiodata(recObj);
sound(data, 16000)
figure(1)
clf
plot(data)