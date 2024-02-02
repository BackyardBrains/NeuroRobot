

%% Get base net
anet = alexnet;


%% Get data
image_dir_name = 'C:\Users\chris\OneDrive\Documents\MATLAB\Selected\';
image_dir = dir(image_dir_name);
nims = size(image_dir, 1)-2;
disp(horzcat('nims: ', num2str(nims)))


%% Label images manually
imageLabeler(image_dir_name)


%% Save
save('gTruth24', 'gTruth24')


%% Train net
load('gTruth24')

trainingData = objectDetectorTrainingData(gTruth24);

options = trainingOptions('sgdm', ...
    'MiniBatchSize', 32, ...
    'InitialLearnRate', 1e-6, ...
    'MaxEpochs', 10, ...
    'executionenvironment', 'gpu', ...
    'verbosefrequency', 5, ...
    'plots', 'training-progress');

rcnn = trainRCNNObjectDetector(trainingData, anet, options);

save(horzcat(nets_dir_name, 'rcnn'), 'rcnn')

