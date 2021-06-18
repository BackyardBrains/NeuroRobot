
%%%% Talking Head Classifier %%%%

close all
clear

%% Settings
net_input_size = [227 227];
fps = 10;
raw_video_filename = 'office13.mp4';
ai_video_filename = 'ai-office13.mp4';

%% Record video
cam_id = 1;
% get_video
get_video_with_ai
keyboard

%% Label video
% videoLabeler
combine_gtruths

%% Prepare pre-trained net
net = alexnet;
% dag_to_rcnn

%% Train net
options = trainingOptions('sgdm', 'Shuffle', 'every-epoch', 'MaxEpochs', 100, ...
    'MiniBatchSize', 128, 'InitialLearnRate', 0.001, 'executionenvironment', 'gpu', ...
    'Plots', 'training-progress');
trainedDetector = trainFastRCNNObjectDetector(trainingData, net, options);
detector_name = horzcat('trainedData_basenet_', num2str(size(net.Layers), 1), ...
    '_MaxEpochs_', num2str(options.MaxEpochs), ...
    '_MiniBatchSize_', num2str(options.MiniBatchSize), ...
    '_InitialLearningRate_', num2str(options.InitialLearningRate));
save(detector_name, 'trainedDetector')

%% Test detector
test_ai_realtime

