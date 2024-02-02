

%% Get base net
if exist('anet', 'var')
    anet = alexnet;
end


%% Get data
image_dir_name = 'C:\Users\chris\OneDrive\Documents\MATLAB\Selected\';
image_dir = dir(image_dir_name);
nims = size(image_dir, 1)-2;
disp(horzcat('nims: ', num2str(nims)))


%% Label images manually
% imageLabeler(image_dir_name)


%% Save
% save('gTruth24', 'gTruth24')


%% Train net
load('gTruth24')

trainingData = objectDetectorTrainingData(gTruth24);

layers = [imageInputLayer([240 320 3])
        convolution2dLayer([5 5],10)
        reluLayer()
        fullyConnectedLayer(2)
        softmaxLayer()
        classificationLayer()];

options = trainingOptions('sgdm', ...
    'MiniBatchSize', 8, ...
    'InitialLearnRate', 1e-6, ...
    'MaxEpochs', 2, ...
    'verbosefrequency', 5, ...
    'plots', 'training-progress');
    % 'executionenvironment', 'gpu', ...

rcnn = trainRCNNObjectDetector(trainingData, layers, options);

save(horzcat(nets_dir_name, 'rcnn'), 'rcnn')

