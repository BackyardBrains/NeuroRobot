 
% imageLabeler(frame_dir)
% save('gTruth', 'gTruth')

load('gTruth')
trainingData = objectDetectorTrainingData(gTruth);
net = alexnet;

% options = trainingOptions('sgdm', 'MiniBatchSize', 16, 'InitialLearnRate', 1e-4, 'MaxEpochs', 5, 'executionenvironment', 'gpu');
% rcnn = trainRCNNObjectDetector(trainingData, net, options);

options = trainingOptions('sgdm', 'MiniBatchSize', 16, 'InitialLearnRate', 1e-3, 'MaxEpochs', 100, 'executionenvironment', 'gpu', 'verbosefrequency', 10);
rcnn = trainFastRCNNObjectDetector(trainingData, net, options);

% options = trainingOptions('sgdm', 'MiniBatchSize', 8, 'InitialLearnRate', 1e-3, 'MaxEpochs', 30, 'executionenvironment', 'gpu');
% rcnn = trainFasterRCNNObjectDetector(trainingData, net, options);

save('rcnn', 'rcnn')