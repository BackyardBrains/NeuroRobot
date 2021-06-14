% Talking Head Classifier

delete(imaqfind)
close all
clear

%% Settings
nsteps = 2000;
fps = 10;
this_size = [288 512];
video_name = 'training_video2.avi';

%% Record video
%1 get_video
shrink_video

%% Label video
%1 videoLabeler % Load training_video.avi, Save labels to gtruthX.mat, Repeat with different background
%2 combine_gtruths
%? load('.\gtruths\gtruth1.mat')

%% Weird preprocessing
load fish_truth3
[frames, boxes] = objectDetectorTrainingData(gTruth, 'SamplingFactor', 1);
data = combine(frames, boxes);

%% Train AI
net = alexnet;
options = trainingOptions('sgdm', 'MaxEpochs', 30, 'MiniBatchSize', 16, 'InitialLearnRate', 0.001, 'executionenvironment', 'gpu');
tic; trainedDetector = trainFastRCNNObjectDetector(data, net, options); toc
save('trainedDetector', 'trainedDetector')




%% Test AI
delete(imaqfind)
close all
clear
load('trainedDetector')
nsteps = 1000;
fps = 10;
this_size = [288 512];
% video_name = 'training_video2.avi';
test_ai

