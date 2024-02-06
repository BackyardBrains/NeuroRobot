
%% Prep and label
% if ~exist('vnet', 'var')
%     % anet = alexnet;
%     vnet = vgg19;
% end

% %% Get data
image_dir_name = 'C:\Users\chris\OneDrive\Documents\MATLAB\Selected\livingroomWebcam\';

image_dir = dir(horzcat(image_dir_name, '*.png'));
nims = size(image_dir, 1);
disp(horzcat('nims: ', num2str(nims)))

imageLabeler(image_dir_name)



%% Train net
% save('livingroom_chris_gTruth', 'livingroom_chris_gTruth')

load('livingroom_chris_gTruth')

trainingData = objectDetectorTrainingData(livingroom_chris_gTruth);

% Net
layers = [
    imageInputLayer([227 302 3])
    convolution2dLayer(3, 16)
    reluLayer  
    convolution2dLayer(3, 8)
    reluLayer     
    maxPooling2dLayer(2,'Stride',2)
    fullyConnectedLayer(400)
    reluLayer 
    fullyConnectedLayer(300)
    reluLayer     
    fullyConnectedLayer(2)
    softmaxLayer()
    classificationLayer()
    ];

% try adam optimizer
options = trainingOptions('sgdm', 'MiniBatchSize', 32, ...
    'InitialLearnRate', 1e-5, 'MaxEpochs', 5, ...
    'verbosefrequency', 5, 'plots', 'training-progress');

rcnn = trainFastRCNNObjectDetector(trainingData, layers, options);

save(horzcat(nets_dir_name, 'rcnn'), 'rcnn')

