
% shrink_video
% videoLabeler
combine_gtruths
% load('trainingData')
% dag_to_rcnn
net = alexnet;
options = trainingOptions('sgdm', 'Shuffle', 'every-epoch', 'MaxEpochs', 100, ...
    'MiniBatchSize', 128, 'InitialLearnRate', 0.0025, 'executionenvironment', 'gpu', ...
    'Plots', 'training-progress');
trainedDetector = trainFastRCNNObjectDetector(trainingData, net, options);
save('trainedDetector', 'trainedDetector')
% load('trainedDetector')
% test_fish_detector
