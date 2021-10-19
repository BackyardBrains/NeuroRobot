
%% Speaker setup
fs = 16000;
nsteps = 10;
speaker_obj = audioDeviceWriter('SampleRate', fs, 'SupportVariableSizeInput', 1);
speaker_obj([0 0 0 0]);

%%
xsound = [];
for nstep = 1:nsteps
    
    disp(num2str(nstep))
    
    these_tones = [...
        261.63, 293.67, 329.63, 349.23, 392.00, 440.00, 493.88, ...
        523.25, 587.33, 659.26, 698.46, 783.99, 880.00, 987.77, ...
        1046.5];
    
    these_tones2 = [...
        277.18, 311.13, 369.99, 415.30, 466.16, ...
        554.37, 622.25, 739.99, 830.61, 932.33];
    
    xtones = randsample(length(these_tones), 1 + round(6 * rand));
    xtones = sort(xtones);
    xtones(diff(xtones) == 1) = [];
    
    xtones2 = randsample(length(these_tones2), round(0.5 * rand));
    xtones2 = sort(xtones2);
    xtones2(diff(xtones2) == 1) = [];    
    
    dxduration = 1;
    
    dxvalues = 1/fs:1/fs:dxduration;

    these_tones = these_tones(xtones) / 2;
    these_tones2 = these_tones2(xtones2);

    ntones = length(these_tones);
    ntones2 = length(these_tones2);

    tone_data = zeros(1, length(dxvalues));
    
    for ntone = 1:ntones
        tone_data = tone_data + sin(2*pi*these_tones(ntone)*dxvalues);
    end
    
    for ntone2 = 1:ntones2
        tone_data = tone_data + sin(2*pi*these_tones2(ntone2)*dxvalues);
    end
    
    tone_data = tone_data / (ntones + ntones2);
    
%     tone_data = tone_data / ntones;
    
    if ~isempty(tone_data)
        n = length(tone_data);
        m = 5;
        nx = round(linspace(1, n, m + 1));
        for xstep = 1:m
            this_audio = tone_data(nx(xstep) : nx(xstep + 1));
            speaker_obj(this_audio');
%             soundsc(this_audio, fs)
        end
    else
        keyboard
    end
    
%     soundsc(tone_data, fs)
    xsound = [xsound tone_data];
    
    
end

figure(1)
clf
subplot(2,1,1)
plot(xsound)
subplot(2,1,2)
pspectrum(xsound, fs, 'spectrogram','FrequencyLimits',[0,1500])

% %%
% sound(xsound, fs)
% figure(1)
% clf
% pspectrum(xsound, fs, 'spectrogram','FrequencyLimits',[0,1500])
