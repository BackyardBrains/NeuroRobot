 
close all
clear
clc

%% Set dir
frame_dir = 'C:\Users\chris\OneDrive\Documents\MATLAB\Selected\';


%% Resize if needed
dir_info = dir(frame_dir);
ii = size(dir_info, 1);
disp(horzcat('npics in current directory: ', num2str(ii)))

aa = [];
for n = 1:ii
    a = dir_info(n).name;
    if length(a) == 14
        file_name = horzcat(frame_dir, a);
        frame = imread(file_name, 'png');
        x = size(frame, 1);
        if x ~= 227
            frame = imresize(frame, [227 227]);
            imwrite(frame, file_name)
            disp('file resized')
        end
        aa = [aa; size(frame)];        
    end
    disp(num2str(n))
end


%% Label images manually
% imageLabeler(frame_dir)
save('gTruth', 'gTruth')
load('gTruth')


%% Train net
trainingData = objectDetectorTrainingData(gTruth);
net = alexnet;

options = trainingOptions('sgdm', 'verbosefrequency', 1, 'plots', 'training-progress');
rcnn = trainFasterRCNNObjectDetector(trainingData, net, options);

% options = trainingOptions('sgdm', 'MiniBatchSize', 1, 'InitialLearnRate', 1e-6, 'MaxEpochs', 10, 'executionenvironment', 'gpu', 'verbosefrequency', 100);
% rcnn = trainFasterRCNNObjectDetector(trainingData, net, options);

save('rcnn', 'rcnn')
