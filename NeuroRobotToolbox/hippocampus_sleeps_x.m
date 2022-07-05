

close all
clear
clc

this_dir = '.\Data_1\Rec_2\';
ims = imageDatastore(this_dir,'IncludeSubFolders',true','LabelSource','foldernames');
ims.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
imdim = 50;

% dist_ds = arrayDatastore(distance);
% final_ds = combine(img_ds, dist_ds);


%%

net = [
    imageInputLayer([imdim imdim 3],"Name","imageinput")
    convolution2dLayer([3 3],32,"Name","conv","Padding","same")
    reluLayer("Name","relu_1")
%     maxPooling2dLayer(2,'Stride',2)
    fullyConnectedLayer(500,"Name","fc_1")
    reluLayer("Name","relu_2")
    fullyConnectedLayer(400,"Name","fc_2")
%     reluLayer("Name","relu_3")
%     fullyConnectedLayer(300,"Name","fc_3")    
    reluLayer("Name","relu_4")
    fullyConnectedLayer(24,"Name","fc_4")
    classificationLayer("Name","classoutput")];

options = trainingOptions('adam', 'ExecutionEnvironment', 'auto', Plots="training-progress");

options = trainingOptions("sgdm", ...
    InitialLearnRate=0.0001,...
    LearnRateSchedule="piecewise", ...
    LearnRateDropFactor=0.2, ...
    LearnRateDropPeriod=5, ...
    MaxEpochs=20, ...
    MiniBatchSize=64, ...
    Plots="training-progress")

net = trainNetwork(ims, net, options)


%%


serials = dir(strcat(this_dir, '*serial_data.mat'));
nserials = size(serials, 1);
distance = zeros(nserials * 2, 1);
for nserial = 1:nserials
    if ~rem(nserial, round(nserials/10))
        disp(num2str(nserial/(nserials)))
    end    
    load(horzcat(this_dir, serials(nserial).name))
    this_distance = str2double(serial_data{3});
    this_distance(this_distance >= 4000) = 0;
    if this_distance
        this_distance = this_distance/4000;
    end
    distance(nserial*2-1:nserial*2) = this_distance;
end

dist_ds = arrayDatastore(distance);

img_ds = imageDatastore(strcat(this_dir, '*uframe.png'));
nimgs = size(img_ds.Files, 1);
img_ds.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually

final_ds = combine(img_ds, dist_ds);