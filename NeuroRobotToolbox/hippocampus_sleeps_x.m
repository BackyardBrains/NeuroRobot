

close all
clear
clc

this_dir = '.\Data\';
ims = imageDatastore(this_dir,'IncludeSubFolders',true','LabelSource','foldernames');
ims.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
imdim = 50;


dist_ds = arrayDatastore(distance);

img_ds = imageDatastore(strcat(this_dir, '*uframe.png'));
nimgs = size(img_ds.Files, 1);
img_ds.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually

final_ds = combine(img_ds, dist_ds);


%%

net = [
    imageInputLayer([imdim imdim 3],"Name","imageinput")
    convolution2dLayer([3 3],32,"Name","conv","Padding","same")
    reluLayer("Name","relu_1")
    fullyConnectedLayer(400,"Name","fc_1")
    reluLayer("Name","relu_2")
    fullyConnectedLayer(300,"Name","fc_2")
    reluLayer("Name","relu_3")
    fullyConnectedLayer(60,"Name","fc_3")
    classificationLayer("Name","classoutput")];

options = trainingOptions('adam', ...
    'MaxEpochs',15,'InitialLearnRate',0.1, ...
    'ExecutionEnvironment', 'parallel', Plots="training-progress", ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropFactor=0.2, ...
    LearnRateDropPeriod=5);

net = trainNetwork(ims, net, options)


%%

imdim = 50;

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