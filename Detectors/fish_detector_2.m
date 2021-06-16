
shrink_video
videoLabeler

% combine_gtruths
% load x5_truth
% trainingData = objectDetectorTrainingData(gTruth, 'SamplingFactor', 1, 'WriteLocation', '.\frames')' ;
% save('trainingData')
% load('trainingData')

% dag_to_rcnn
net = alexnet;
options = trainingOptions('sgdm', 'Shuffle', 'every-epoch', 'MaxEpochs', 100, ...
    'MiniBatchSize', 128, 'InitialLearnRate', 0.0001, 'executionenvironment', 'gpu', ...
    'Plots', 'training-progress');
trainedDetector = trainFastRCNNObjectDetector(trainingData, net, options);
save('trainedDetector', 'trainedDetector')

% test_fish_detector
