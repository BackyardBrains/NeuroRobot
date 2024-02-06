
close all
clear
clc

image_dir_name = 'C:\Users\chris\OneDrive\Documents\MATLAB\Selected\office1\';
image_dir = dir(horzcat(image_dir_name, '*.png'));
nims = size(image_dir, 1);
disp(horzcat('nims: ', num2str(nims)))

% imageLabeler(image_dir_name)

% save('livingroom_chris_gTruth', 'livingroom_chris_gTruth')

load('C:\Users\chris\OneDrive\Documents\MATLAB\Selected\office1_prj.mat')

trainingData = objectDetectorTrainingData(gTruth);


%%

layers = [
    imageInputLayer([227 302 3])
    convolution2dLayer(5, 20)
    reluLayer()
    maxPooling2dLayer(2, 'Stride', 2)
    fullyConnectedLayer(2)
    softmaxLayer()
    classificationLayer()
    ];

options = trainingOptions('sgdm', ...
    'MiniBatchSize', 128, ...
    'InitialLearnRate', 1e-6, ...
    'MaxEpochs', 5, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropFactor', 0.2, ...
    'LearnRateDropPeriod', 2, ...
    'Verbose', true, 'Plots','training-progress');
    
rcnn = trainRCNNObjectDetector(trainingData, layers, options, ...
'NegativeOverlapRange', [0 0.3], 'PositiveOverlapRange',[0.5 1]);

save(horzcat(nets_dir_name, 'rcnn'), 'rcnn')


%%
% figure(1)
% clf
% im = imread(cell2mat(trainingData{1,1}));
% image(im)
% hold on
% this_im = imresize(im, [227 302]);
% load(horzcat(nets_dir_name, 'rcnn'))
% [bbox, score, label] = detect(rcnn, this_im);
% [cone_score, cone_ind] = max(score);
% cbox = bbox(cone_ind, :)
% hold on
% plot(cbox(2) + cbox(4)/2, cbox(1) + cbox(3)/2, 'Marker', '.', 'color', [0.2 0.8 0.2], 'markersize', 30)

nframe = randsample(243, 1);

filename = trainingData{nframe,1}{1,1};
bbox = trainingData{nframe,2}{1,:};

im = imread(filename);

figure(10)
clf
set(gcf, 'position', [485 294 935 484]);

image(im)
hold on

for nbox = 1:size(bbox, 1)
    rectangle('position', bbox(nbox, :), 'linewidth', 2, 'edgecolor', 'r')
end

[bbox, score, label] = detect(rcnn, im, 'NumStrongestRegions', 2000, 'MiniBatchSize', 128);

[cone_score, cone_ind] = max(score);

if ~isempty(cone_ind)
    title(horzcat('nframe: ', num2str(nframe), ', score: ', num2str(cone_score)))
    rectangle('position', bbox(cone_ind, :), 'linewidth', 2, 'edgecolor', 'g');
end
