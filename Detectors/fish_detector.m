
% shrink_video
% videoLabeler
combine_gtruths
% load('trainingData')
% dag_to_rcnn
net = alexnet;
options = trainingOptions('sgdm', 'Shuffle', 'every-epoch', 'MaxEpochs', 100, ...
    'MiniBatchSize', 128, 'InitialLearnRate', 0.001, 'executionenvironment', 'gpu', ...
    'Plots', 'training-progress');
trainedDetector = trainFastRCNNObjectDetector(trainingData, net, options);
detector_name = horzcat('trainedData_basenet_', num2str(size(net.Layers), 1), ...
    '_MaxEpochs_', num2str(options.MaxEpochs), ...
    '_MiniBatchSize_', num2str(options.MiniBatchSize), ...
    '_InitialLearningRate_', num2str(options.InitialLearningRate));
save(detector_name, 'trainedDetector')
% load('trainedDetector')
test_fish_detector
