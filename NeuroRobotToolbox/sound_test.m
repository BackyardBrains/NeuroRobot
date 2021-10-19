
tone_duration = 0.5;
pause_duration = 0.5;
nrepeats = 3;
fs = 16000;

speaker_obj = audioDeviceWriter('SampleRate', fs, 'SupportVariableSizeInput', 1);
speaker_obj([0 0 0 0])

dxvalues = 1/fs:1/fs:tone_duration;

for nstep = 1:nrepeats
    tic
    this_audio = sin(2*pi*(300 + (nstep * 50))*dxvalues);
    soundsc(this_audio, fs)
    speaker_obj(this_audio')
    while toc < pause_duration
        pause(0.001)
    end
end