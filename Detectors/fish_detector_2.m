
close all
clear

% shrink_video
% videoLabeler
% combine_gtruths

load x5_truth
trainingData = objectDetectorTrainingData(gTruth, 'SamplingFactor', 1, 'WriteLocation', '.\frames')' ;
% load('trainingData')

% dag_to_rcnn
net = alexnet;
options = trainingOptions('sgdm', 'Shuffle', 'every-epoch', 'MaxEpochs', 5, ...
    'MiniBatchSize', 128, 'InitialLearnRate', 0.001, 'executionenvironment', 'gpu');
trainedDetector = trainFastRCNNObjectDetector(trainingData, net, options);
save('trainedDetector', 'trainedDetector')

% test_fish_detector
