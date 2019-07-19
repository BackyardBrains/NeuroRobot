 
% imageLabeler(frame_dir)
% save('gTruth', 'gTruth')
% 
load('gTruth')
trainingData = objectDetectorTrainingData(gTruth);

net = alexnet;

% options = trainingOptions('sgdm');
% options = trainingOptions('sgdm', 'MiniBatchSize', 8, 'InitialLearnRate', 1e-6, 'MaxEpochs', 4);
options_fast = trainingOptions('sgdm', 'MiniBatchSize', 8, 'InitialLearnRate', 1e-3, 'MaxEpochs', 60, 'executionenvironment', 'gpu');
% rcnn = trainRCNNObjectDetector(trainingData, net, options);


save('rcnn', 'rcnn')