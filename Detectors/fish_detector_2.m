
% close all
% clear

% shrink_video
% videoLabeler
% combine_gtruths

% load hero_truth_51
% data = objectDetectorTrainingData(gTruth, 'SamplingFactor', 1, 'WriteLocation', '.\frames')' ;
load('trainingData')
data = trainingData;
net = alexnet;
options = trainingOptions('sgdm', 'Shuffle', 'every-epoch', 'MaxEpochs', 100, ...
    'MiniBatchSize', 32, 'InitialLearnRate', 0.0001, 'executionenvironment', 'gpu', ...
    'Plots', 'training-progress');
trainedDetector = trainFastRCNNObjectDetector(data, net, options);
save('trainedDetector', 'trainedDetector')

% test_fish_detector
