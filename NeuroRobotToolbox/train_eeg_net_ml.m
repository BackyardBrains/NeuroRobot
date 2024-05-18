
% This script trains different network architectures on the 78 rec dataset

% close all
% clear
% clc


%% Settings
recording_length_in_sec = 30;
sample_frequency = 3333;
target_frequency = 250;
data_dir = 'C:\Users\chris\EEG\Data1\';
nclasses = 2; % Eyes open (1) & Eyes closed (2)
sample_length = recording_length_in_sec * target_frequency;

if ~exist('raw_settings', 'var')
    network_type = 1; % 1 = CWT, 2 = LSTM
    ml_me = 20; % Max epochs
else

end


%% Get data
wavFiles = dir(fullfile(data_dir, '*.wav'));
noteFiles = dir(fullfile(data_dir, '*-events.txt'));

nfiles = length(wavFiles);

nsamples_per_recording = (target_frequency * recording_length_in_sec - target_frequency) / 10;
data = zeros(nfiles, nsamples_per_recording, target_frequency);
labels = zeros(nfiles, 1);

disp('Getting data...')
for fileIdx = 1:nfiles

    if ~rem(fileIdx+1, round(nfiles/10))
        disp(horzcat(num2str(round(100*(fileIdx/nfiles))), '% done'))
    end

    waveFilename = wavFiles(fileIdx).name;
    textFileName = strrep(waveFilename,'.wav','-events.txt');

    [wave,sample_frequency] = audioread([data_dir waveFilename]);
    wave = wave(1:recording_length_in_sec*sample_frequency, 1);
    wave_downsampled = resample(wave,target_frequency,sample_frequency);

    clear eventData
    eventData = importdata([data_dir textFileName], '\t', 2);
    marker_times = eventData.data;
    marker_times_downsampled = marker_times * target_frequency;

    dcounter = 0;
    for ii = 1:10:sample_length-target_frequency
        dcounter = dcounter + 1;
        this_data = wave_downsampled(ii : ii + target_frequency - 1);
        data(fileIdx, dcounter, :) = this_data;
        if ii < marker_times_downsampled(1)
            labels(fileIdx, dcounter) = 1;
        elseif ii < marker_times_downsampled(2)
            labels(fileIdx, dcounter) = 0;
        elseif ii < marker_times_downsampled(3)
            labels(fileIdx, dcounter) = 1;
        elseif ii < marker_times_downsampled(4)
            labels(fileIdx, dcounter) = 0;
        else
            labels(fileIdx, dcounter) = 1;
        end
    end
end

disp('Pre-processing...')
xdata = cell(nfiles*nsamples_per_recording, 1);
xlabels = zeros(nfiles*nsamples_per_recording, 1);
xspectrum = zeros(nfiles*nsamples_per_recording, 2);
counter = 0;
for fileIdx = 1:nfiles
    fileIdx 
    for jj = 1:nsamples_per_recording
        counter = counter + 1;
        this_data = squeeze(data(fileIdx, jj, :));
        this_data = reshape(this_data,1,[]);
        xdata{counter} = this_data;
        xlabels(counter) = labels(fileIdx, jj);

        % Get pspectrum alpha
        [p, f, ~] = pspectrum(...
            zscore(this_data),...
            target_frequency,...
            'spectrogram',...
            'TimeResolution', 0.01,...
            'OverlapPercent',0,...
            'FrequencyLimits',[0 25]);
        alpha = mean(p(f > 8 & f < 12));

        % Get fft alpha
        n = target_frequency;
        nyq = fix(n/2);
        p = abs(fft(this_data));
        f = (0:(n-1))/n*target_frequency; 
        p = p(1:nyq);
        f = f(1:nyq);
        these_fs = find(f > 8 & f < 12);
        t = (0:(n-1))/target_frequency;
        alpha2 = mean(p(these_fs));        

        xspectrum(counter, 1) = alpha;
        xspectrum(counter, 2) = alpha2;        

    end
end
xlabels = categorical(xlabels);


%%
idx = splitlabels(xlabels,[0.7 0.2 0.1]);
training_data = xdata(idx{1});
training_labels = xlabels(idx{1});
test_data = xdata(idx{2});
test_labels = xlabels(idx{2});
validation_data = xdata(idx{3});
validation_labels = xlabels(idx{3});


%% Prepare network
sequence_length = target_frequency;

if network_type == 1

    layers = [
        sequenceInputLayer(1,"MinLength",sequence_length,"Name","input","Normalization","zscore")
        convolution1dLayer(5,1,"stride",2)
        cwtLayer("SignalLength",round(sequence_length/2),"IncludeLowpass",true,"Wavelet","amor")
        maxPooling2dLayer([5,10])
        convolution2dLayer([5,10],5,"Padding","same")
        maxPooling2dLayer([5,10])
        batchNormalizationLayer
        reluLayer
        convolution2dLayer([5,10],10,"Padding","same")
        maxPooling2dLayer([2,4])
        batchNormalizationLayer
        reluLayer
        flattenLayer
        globalAveragePooling1dLayer
        dropoutLayer(0.4)
        fullyConnectedLayer(nclasses)
        softmaxLayer
        classificationLayer
        ];

    options = trainingOptions("adam", ...
        "MaxEpochs",ml_me, ...
        "MiniBatchSize",ml_bs, ...
        "Shuffle","every-epoch",...
        "ValidationData",{validation_data,validation_labels},...
        "L2Regularization",1e-2,...
        "OutputNetwork","best-validation-loss",...
        "Verbose", true);

elseif network_type == 2

    layers = [
        sequenceInputLayer(1)
        % lstmLayer(100, 'OutputMode', 'last')
        bilstmLayer(100,'OutputMode','last')
        fullyConnectedLayer(nclasses)
        softmaxLayer
        classificationLayer
        ];

    options = trainingOptions('adam', ...
        'MaxEpochs', ml_me, ...
        'MiniBatchSize', ml_bs, ...
        'Verbose', true, ...
        "Shuffle","every-epoch",...
        "ValidationData",{validation_data,validation_labels},...
        "Plots", "none");

end


%%
net = trainNetwork(xdata, xlabels, layers, options);
% net = trainnet(xdata, xlabels, layers, 'crossentropy', options)
save(strcat(data_dir, 'eegNet'), 'net')


%%
% Make predictions on testing data
predicted_labels = classify(net, test_data);

% Evaluate the predictions
accuracy = sum(predicted_labels == test_labels) / length(predicted_labels);
disp(['Accuracy: ', num2str(accuracy * 100), '%']);
