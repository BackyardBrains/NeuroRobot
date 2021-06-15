
% close all
% clear

% shrink_video
% videoLabeler
% combine_gtruths

% load hero_truth_51
% data = objectDetectorTrainingData(gTruth, 'SamplingFactor', 1, 'WriteLocation', '.\frames')' ;
load('trainingData')
data = trainingData;

dag_to_rcnn

options = trainingOptions('sgdm', 'Shuffle', 'every-epoch', 'MaxEpochs', 20, ...
    'MiniBatchSize', 24, 'InitialLearnRate', 0.001, 'executionenvironment', 'gpu');
trainedDetector = trainFastRCNNObjectDetector(data, lgraph, options);
save('trainedDetector', 'trainedDetector')

% test_fish_detector
