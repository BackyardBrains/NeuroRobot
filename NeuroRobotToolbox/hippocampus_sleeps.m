

close all
clear
clc

this_dir = '.\Data_1\Rec_3\';
ims = imageDatastore(this_dir,'IncludeSubFolders',true','LabelSource','foldernames');
% ims.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
imdim = 227;

% dist_ds = arrayDatastore(distance);
% final_ds = combine(img_ds, dist_ds);

net = [
    imageInputLayer([imdim imdim 3])
    
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    fullyConnectedLayer(32)
    softmaxLayer
    classificationLayer];

options = trainingOptions('adam', 'ExecutionEnvironment', 'auto', ...
    Plots="training-progress", Shuffle ='every-epoch', MaxEpochs=10);

net = trainNetwork(ims, net, options);

save('livingroom_k32_net', 'net')



