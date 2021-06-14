
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
options = trainingOptions('adam', 'Shuffle', 'every-epoch', 'MaxEpochs', 10, 'MiniBatchSize', 128, 'InitialLearnRate', 0.0001, 'executionenvironment', 'gpu');
trainedDetector = trainFastRCNNObjectDetector(data, net, options);
save('trainedDetector', 'trainedDetector')
% test_fish_detector
