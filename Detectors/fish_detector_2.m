
close all
clear
% shrink_video
% videoLabeler
% combine_gtruths
load hero_truth_51
data = objectDetectorTrainingData(gTruth, 'SamplingFactor', 1);
% data = combine(frames, boxes);
% count = 0; for ii = 1:size(boxes.LabelData) count = count + size(boxes.LabelData{263}, 1); end count
net = alexnet;
options = trainingOptions('sgdm', 'MaxEpochs', 30, 'MiniBatchSize', 64, 'InitialLearnRate', 0.0001, 'executionenvironment', 'gpu', 'Plots', 'training-progress');
trainedDetector = trainRCNNObjectDetector(data, net, options);
save('trainedDetector', 'trainedDetector')
% test_fish_detector
