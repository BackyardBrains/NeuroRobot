

%% Get data
image_dir_name = 'C:\Users\chris\OneDrive\Documents\MATLAB\Selected\';
image_dir = dir(image_dir_name);
nims = size(image_dir, 1);
disp(horzcat('nims: ', num2str(nims)))


%% Label images manually
% imageLabeler(image_dir_name)
% save('gTruth', 'gTruth')
load('gTruth')


%% Train net
trainingData = objectDetectorTrainingData(gTruth);
anet = alexnet;

options = trainingOptions('sgdm', ...
    'MiniBatchSize', 8, ...
    'MaxEpochs', 20, ...
    'InitialLearnRate', 1e-6, ...
    'LearnRateSchedule', "piecewise", ...
    'LearnRateDropFactor', 0.25, ...
    'LearnRateDropPeriod', 5, ...
    'executionenvironment', 'gpu', ...
    'verbosefrequency', 10, ...
    'plots', 'training-progress');
rcnn = trainFasterRCNNObjectDetector(trainingData, anet, options);

save('rcnn', 'rcnn')
