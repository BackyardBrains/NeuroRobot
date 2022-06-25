
close all
clear
clc

rootdir = '.\Data\';
filelist = dir(fullfile(rootdir, '**\*.png'));  %get list of files and folders in any subfolder
states = folders2labels(rootdir);
ustates = unique(states);
nustates = length(ustates);
img_ds = imageDatastore(rootdir, 'IncludeSubfolders',true,'LabelSource','foldernames');
nimgs = size(img_ds.Files, 1);
img_ds.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually

% net = [
%     imageInputLayer([50 50 3],"Name","imageinput","Normalization","none")
%     convolution2dLayer([5 5],16,"Name","conv")
%     batchNormalizationLayer("Name","batchnorm")
%     reluLayer("Name","relu_1")
%     fullyConnectedLayer(50,"Name","fc_1")
%     reluLayer("Name","relu_2")
%     fullyConnectedLayer(60,"Name","fc_2")
%     softmaxLayer("Name","softmax")
%     classificationLayer("Name","classoutput")];

% featInput = featureInputLayer(1,Name="features",Normalization="none");
% lgraph = addLayers(lgraph,featInput);
% lgraph = connectLayers(lgraph,"features","cat/in2");

% options = trainingOptions("adam", Plots="training-progress")

options = trainingOptions("sgdm", ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropFactor=0.2, ...
    LearnRateDropPeriod=5, ...
    MaxEpochs=20, ...
    MiniBatchSize=64, ...
    Plots="training-progress")

net = trainNetwork(img_ds, net, options)

% save('rl_net', 'net')

%%
% load('rl_net')
lgraph = layerGraph(net);
plot(lgraph)
ii = 424; this_im = readimage(img_ds, ii); figure(1); clf; image(this_im)

classify(net, this_im)
