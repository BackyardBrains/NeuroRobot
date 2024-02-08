
close all
clear
clc

% anet = alexnet;
nets_dir_name = strcat(userpath, '\Nets\');
image_dir_name = 'C:\Users\chris\OneDrive\Documents\MATLAB\Selected\office2\';
image_dir = dir(horzcat(image_dir_name, '*.png'));
nims = size(image_dir, 1);
disp(horzcat('nims: ', num2str(nims)))

% imageLabeler(image_dir_name)

%%
% save('C:\Users\chris\OneDrive\Documents\MATLAB\Selected\office2_gTruth', 'office2_gTruth')

load('C:\Users\chris\OneDrive\Documents\MATLAB\Selected\office2_gTruth')

trainingData = objectDetectorTrainingData(office2_gTruth);


%%
filterSize = [5 5];
numFilters = 128;

layers = [
    
    imageInputLayer([227 302 3])
    
    convolution2dLayer(filterSize,numFilters,'Padding',2)
    reluLayer()
    maxPooling2dLayer(3,'Stride',2)
    
    convolution2dLayer(filterSize,numFilters,'Padding',2)
    reluLayer()
    maxPooling2dLayer(3,'Stride',2)

    convolution2dLayer(filterSize,numFilters/2,'Padding',2)
    reluLayer()
    maxPooling2dLayer(3,'Stride',2)

    convolution2dLayer(filterSize,numFilters/2,'Padding',2)
    reluLayer()
    maxPooling2dLayer(3,'Stride',2)

    fullyConnectedLayer(1000)
    reluLayer

    fullyConnectedLayer(800)
    reluLayer    

    fullyConnectedLayer(600)
    reluLayer

    fullyConnectedLayer(400)
    reluLayer
    
    fullyConnectedLayer(3)
    softmaxLayer
    classificationLayer

    ];

options = trainingOptions('sgdm', ...
    'MiniBatchSize', 16, ...
    'InitialLearnRate', 1e-6, ...
    'MaxEpochs', 20, ...
    'Verbose', true, 'Plots','training-progress');

% rcnn = trainRCNNObjectDetector(trainingData, layers, options, ...
% 'NegativeOverlapRange', [0 0.3]);
% 
% save(horzcat(nets_dir_name, 'rcnn4'), 'rcnn')


%%


nframe = randsample(236, 1);


filename = trainingData{nframe,1}{1,1};
bbox = trainingData{nframe,2}{1,:};
cbox = trainingData{nframe,3}{1,:};

im = imread(filename);

figure(10)
clf
set(gcf, 'position', [485 294 935 484]);

image(im)
hold on

for nbox = 1:size(bbox, 1)
    rectangle('position', bbox(nbox, :), 'linewidth', 2, 'edgecolor', 'r')
end

for nbox = 1:size(cbox, 1)
    rectangle('position', cbox(nbox, :), 'linewidth', 2, 'edgecolor', 'g')
end


[bbox, score, label] = detect(rcnn, im, 'NumStrongestRegions', 500, 'MiniBatchSize', 16);

[mscore, mind] = max(score);

if ~isempty(mind)
    title(horzcat('nframe: ', num2str(nframe), ', score: ', num2str(mscore)))
    rectangle('position', bbox(mind, :), 'linewidth', 2, 'edgecolor', [1 0.5 0]);
    disp(label(mind))
else
    title(horzcat('nframe: ', num2str(nframe), ', label: ', 'No label'))
    disp('No label')
end

