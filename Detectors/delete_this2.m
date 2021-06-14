
clear

imageDir = fullfile(matlabroot, 'toolbox', 'vision', 'visiondata', 'vehicles');
addpath(imageDir);
    
% Load training data
load('vehicleTrainingData.mat');
load('stopSignsAndCars.mat');

%% Vertically concatenate image file locations
tb1_filenames = vehicleTrainingData(:,1);
tb2_filenames = stopSignsAndCars(:,1);
all_filenames = [tb1_filenames; tb2_filenames];
n_all = size(all_filenames, 1);


%% Vertically concatenate bounding boxes
tb1_boxes = vehicleTrainingData(:,2);
tb2_boxes = stopSignsAndCars(:,2);
n_tb1 = size(tb1_boxes, 1);
n_tb2 = size(tb2_boxes, 1);
trainingDataTable = cell(n_all,3);
trainingDataTable = cell2table(trainingDataTable);
trainingDataTable(:, 1) = all_filenames;
trainingDataTable.Properties.VariableNames = {'filenames', 'car', 'stopsign'};

for ii = 1:n_all
    if ii <= n_tb1
        trainingDataTable(ii, 2) = tb1_boxes(ii, :);
    else
        trainingDataTable(ii, 3) = tb2_boxes(ii-n_tb1, :);
    end
end

% Train net
options = trainingOptions('sgdm', 'MaxEpochs', 5, 'Verbose', true, 'executionenvironment', 'gpu');
net = alexnet;
rcnn = trainRCNNObjectDetector(trainingDataTable, net, options);


