

%% Get base net
if exist('snet', 'var')
    % anet = alexnet;
    snet = squeezenet;
end


%% Get data
image_dir_name = 'C:\Users\chris\OneDrive\Documents\MATLAB\Selected\office\';
image_dir = dir(image_dir_name);
nims = size(image_dir, 1)-2;
disp(horzcat('nims: ', num2str(nims)))


%% Label images manually
imageLabeler(image_dir_name)


%% Save
save('office_gTruth_2024', 'office_gTruth_2024')


%% Train net
load('office_gTruth_2024')

trainingData = objectDetectorTrainingData(office_gTruth_2024);

% Net
layers = [
    imageInputLayer([240 320 3])
    convolution2dLayer(3,16,"Padding","same")
    reluLayer
    convolution2dLayer(3,8,"Padding","same")
    reluLayer
    maxPooling2dLayer(2,'Stride',2)
    fullyConnectedLayer(200)
    reluLayer
    fullyConnectedLayer(100)
    reluLayer    
    fullyConnectedLayer(3)
    softmaxLayer()
    classificationLayer()
    ];

options = trainingOptions('sgdm', ...
    'MiniBatchSize', 32, ...
    'InitialLearnRate', 1e-6, ...
    'MaxEpochs', 20, ...
    'verbosefrequency', 5, ...
    'plots', 'training-progress');

rcnn = trainRCNNObjectDetector(trainingData, layers, options);

save(horzcat(nets_dir_name, 'rcnn'), 'rcnn')

