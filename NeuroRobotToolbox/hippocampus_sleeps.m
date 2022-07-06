

close all
clear
clc

this_dir = '.\Data_1\Rec_2\';
ims = imageDatastore(this_dir,'IncludeSubFolders',true','LabelSource','foldernames');
ims.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
imdim = 227;

% dist_ds = arrayDatastore(distance);
% final_ds = combine(img_ds, dist_ds);


%%
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
    
    fullyConnectedLayer(24)
    softmaxLayer
    classificationLayer];

options = trainingOptions('adam', 'ExecutionEnvironment', 'auto', ...
    Plots="training-progress", Shuffle ='every-epoch', MaxEpochs=5);

% LearnRateDropFactor=0.5, ...
%     LearnRateDropPeriod=1, ....
%     LearnRateSchedule="piecewise", ...

% options = trainingOptions("sgdm", ...
%     InitialLearnRate=0.001,...
%     MiniBatchSize=64, ...
%     Plots="training-progress")

net = trainNetwork(ims, net, options)

save('livingroom2_net', 'net')


% unique_states = unique(rl_data(:,1));
% for ii = unique_states'
%     these_frames = rl_data(:,1) == ii;
%     if sum(these_frames) > 50
%         figure(ii)
%         montage({frames{these_frames}})
%         title(horzcat('State: ', num2str(ii)))
%         pause
%     end
% end

