% Talking Head Classifier

delete(imaqfind)
close all
clear

% %% Settings
% nsteps = 2000;
% fps = 10;
% this_size = [288 512];
% video_name = 'training_video2.avi';

%% Record video
%1 get_video
% shrink_video

%% Label video
%1 videoLabeler % Load training_video.avi, Save labels to gtruthX.mat, Repeat with different background
%2 combine_gtruths
%? load('.\gtruths\gtruth1.mat')

%% Weird preprocessing
load hero_truth
[frames, boxes] = objectDetectorTrainingData(gTruth, 'SamplingFactor', 1);
data = combine(frames, boxes);

% count = 0;
% for ii = 1:size(boxes.LabelData)
%     count = count + size(boxes.LabelData{263}, 1);
% end
% count

%% Train AI
net = alexnet;
options = trainingOptions('sgdm', 'MaxEpochs', 30, 'MiniBatchSize', 64, 'InitialLearnRate', 0.0001, 'executionenvironment', 'gpu', 'Plots', 'training-progress');
tic; trainedDetector = trainRCNNObjectDetector(data, net, options); toc
save('trainedDetector', 'trainedDetector')
% 
% %% Test AI
% delete(imaqfind)
% close all
% clear
% load('trainedDetector')
% nsteps = 1000;
% fps = 10;
% this_size = [288 512];
% % video_name = 'training_video2.avi';
% test_ai
% 
