
close all
clear
clc

dataset_dir_name = 'C:\Users\chris\OneDrive\Documents\MATLAB\Datasets';
nets_dir_name = 'C:\Users\chris\OneDrive\Documents\MATLAB\Nets';
image_ds = imageDatastore(fullfile(dataset_dir_name, '**\*large_frame_x.png'));
ext_dir = dir(fullfile(dataset_dir_name, '**\*ext_data.mat'));
net_name = 'xyoNet';

ntuples = size(ext_dir, 1);

x1 = 0;
y1 = 0;
x2 = 1;
y2 = 1;


%%

thetas = zeros(ntuples, 1);
robot_xys = zeros(ntuples, 2);
disp(horzcat('Getting ', num2str(ntuples), ' xyos'))

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end

    ext_fname = horzcat(ext_dir(ntuple).folder, '\', ext_dir(ntuple).name);
    load(ext_fname)

    robot_xy = ext_data.robot_xy;
    rblob_xy = ext_data.rblob_xy;    
    gblob_xy = ext_data.gblob_xy;    

    x1 = rblob_xy(1);
    y1 = rblob_xy(2);
    x2 = gblob_xy(1);
    y2 = gblob_xy(2);

    robot_xys(ntuple, :) = robot_xy;

    sepx = x1-x2;
    sepy = y1-y2;

    theta = mod(atan2d(sepy,sepx),360); 
    thetas(ntuple) = theta;

end


%%

xyos = arrayDatastore([robot_xys(:,1) robot_xys(:,2) thetas]);
training_data = combine(image_ds, xyos);
numResponses = 3;

layers = [
    imageInputLayer([240 320 3])    
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer    
    maxPooling2dLayer(2,'Stride',2)  
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2,'Stride',2)
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(400)
    reluLayer
    fullyConnectedLayer(300)
    reluLayer
    fullyConnectedLayer(numResponses)];

% options = trainingOptions('adam', 'ExecutionEnvironment', 'auto', ...
%     MiniBatchSize=128, Plots='training-progress', Shuffle ='every-epoch', ...
%     MaxEpochs=20, VerboseFrequency= 1);

options = trainingOptions("adam", ...
    InitialLearnRate=1e-3, ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropFactor=0.1, ...
    LearnRateDropPeriod=10, ...
    Shuffle="every-epoch", ...
    MaxEpochs=40, ...
    MiniBatchSize=128, ...
    Plots="training-progress", ...
    Metrics="rmse", ...
    Verbose=1);

xyoNet = trainnet(training_data, layers, 'mse', options);

save(strcat(nets_dir_name, net_name), 'xyoNet')

