

clear

%% Use videoLabeler to generate ground truths (one label per file)
available_gtruths = dir('.\gTruths\*.mat');
ntruths = size(available_gtruths, 1);
all_filenames = [];
all_labels{1} = 'filenames';
all_ns = [];
n_unique_labels = 0;
for ntruth = 1:ntruths
    load(horzcat('.\gTruths\gTruth', num2str(ntruth), '.mat'))
    disp(gTruth.DataSource.Source)
    [filenames, boxes] = objectDetectorTrainingData(gTruth, 'WriteLocation', '.\frames');
    save(horzcat('filenames_', num2str(ntruth), '.mat'), 'filenames')
    save(horzcat('boxes_', num2str(ntruth), '.mat'), 'boxes')
%     load(horzcat('filenames_', num2str(ntruth), '.mat'))
%     load(horzcat('boxes_', num2str(ntruth), '.mat'))    
    all_filenames = [all_filenames; filenames.Files];
    label = char(boxes.LabelData{1,2}(1));
    twin = find(strcmp(all_labels, label));
    if isempty(twin)
        n_unique_labels = n_unique_labels + 1;
        all_labels{1, n_unique_labels + 1} = label;
    end
    all_ns = [all_ns; size(filenames.Files, 1)];
end

n_all = size(all_filenames, 1);
trainingDataTable = cell(n_all, n_unique_labels + 1);
trainingDataTable = cell2table(trainingDataTable);
trainingDataTable(:, 1) = all_filenames;
trainingDataTable.Properties.VariableNames = all_labels;
load('boxes_1.mat')
truth_counter = 1;
label_counter = 2;
frame_counter = 0;
biggest = 2;
nframe = 1;
while nframe < n_all
    nframe = nframe + 1;
    frame_counter = frame_counter + 1;
    if nframe <= sum(all_ns(1:truth_counter))
        trainingDataTable{nframe, label_counter} = boxes.LabelData(frame_counter, 1);
    else
        truth_counter = truth_counter + 1;
        load(horzcat('boxes_', num2str(truth_counter), '.mat'))
        label = char(boxes.LabelData{1,2}(1)); 
        twin = find(strcmp(all_labels, label));
        if twin
            biggest = label_counter;
            label_counter = twin;
        else
            label_counter = biggest + 1;
            biggest = label_counter;
        end
        frame_counter = 0;
        nframe = nframe - 1;
    end
end

%% Train net
options = trainingOptions('sgdm', 'MaxEpochs', 5, 'Verbose', true, 'executionenvironment', 'gpu');
net = alexnet;
rcnn = trainRCNNObjectDetector(trainingDataTable, net, options);

% options = trainingOptions('sgdm', 'MiniBatchSize', 16, 'InitialLearnRate', 1e-2, 'MaxEpochs', 5, 'executionenvironment', 'gpu');
% net = trainRCNNObjectDetector(trainingData, net, options);
% save('net', 'net')

%% Test net
v = VideoReader('IMG_6787.mov');
w = read(v, 100);

% C:\Users\Christopher Harris\Talking Head Classifier\Video\IMG_6791.mov
% C:\Users\Christopher Harris\Talking Head Classifier\Video\IMG_6790.mov
% C:\Users\Christopher Harris\Talking Head Classifier\Video\IMG_6789.mov
% C:\Users\Christopher Harris\Talking Head Classifier\Video\IMG_6785.mov
% [bbox, score] = detect(rcnn, frame, 'NumStrongestRegions', 100, 'threshold', 0, 'ExecutionEnvironment', 'gpu');