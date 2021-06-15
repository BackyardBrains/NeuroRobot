
% close all
% clear

% shrink_video
% videoLabeler
% combine_gtruths

% load hero_truth_51
% data = objectDetectorTrainingData(gTruth, 'SamplingFactor', 1);

net = alexnet;
options = trainingOptions('sgdm', 'Shuffle', 'every-epoch', 'MaxEpochs', 300, ...
    'MiniBatchSize', 24, 'InitialLearnRate', 0.0001, 'executionenvironment', 'gpu', ...
    'Plots', 'training-progress');
trainedDetector = trainFastRCNNObjectDetector(data, net, options);
save('trainedDetector', 'trainedDetector')

% test_fish_detector
