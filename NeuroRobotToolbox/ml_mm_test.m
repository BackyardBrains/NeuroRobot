

close all
clear

%%

dataset_dir_name = 'C:\SpikerBot ML Datasets\';
rec_dir_name = 'Rec2*';

image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*.png'));
serial_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*serial_data.mat'));
torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));
ext_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*ext_data.mat'));

ntorques = size(torque_dir, 1);
nimages = size(image_dir, 1);
ntuples = ntorques;
disp(horzcat('ntuples: ', num2str(ntuples)))


%% Prepare
get_ims
get_dists
get_xyos



%%
locat = zeros(ntuples, 1);
for ntuple = 1:ntuples
    if xys(1,ntuple) < 150 && xys(2,ntuple) < 150
        locat(ntuple) = 1;
    elseif xys(1,ntuple) > 150 && xys(2,ntuple) < 100
        locat(ntuple) = 2;
    elseif xys(1,ntuple) < 150 && xys(2,ntuple) > 150
        locat(ntuple) = 3;
    elseif xys(1,ntuple) > 150 && xys(2,ntuple) > 150
        locat(ntuple) = 4;
    else
        locat(ntuple) = randsample(4, 1);
    end
end

locat = categorical(locat);
figure(3)
clf
subplot(3,1,1)
histogram(locat)
title('labels')

%%
os = zeros(ntuples,1);
for ntuple = 1:ntuples
    os(ntuple) = atan2(rblob(2,ntuple) - gblob(2,ntuple), rblob(1,ntuple) - gblob(1,ntuple)) * 180 / pi;
end
subplot(3,1,2)
histogram(os)
title('Orientations')


%%

% rand_idx = randperm(ntuples,ntuples);
% locat = locat(rand_idx);

dsX1Train = arrayDatastore(ims,IterationDimension=4);       % images (bw esp32 cam frames)
dsX2Train = arrayDatastore(dists);                        % numbers (dists)
dsTTrain = arrayDatastore(locat);                          % labels (1-4)
dsTrain = combine(dsX1Train,dsX2Train,dsTTrain);            % combined


%% Initialize net
[h,w,numChannels,numObservations] = size(ims);
numFeatures = 1;
numClasses = numel(categories(locat));

imageInputSize = [h w numChannels];
filterSize = 5;
numFilters = 16;

layers = [
    imageInputLayer(imageInputSize,Normalization="none")
    convolution2dLayer(filterSize,numFilters)
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(50)
    flattenLayer
    concatenationLayer(1,2,Name="cat")
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];


lgraph = layerGraph(layers);

featInput = featureInputLayer(numFeatures,Name="features");
lgraph = addLayers(lgraph,featInput);
lgraph = connectLayers(lgraph,"features","cat/in2");

options = trainingOptions("sgdm", ...
    MaxEpochs=15, ...
    InitialLearnRate=0.01, ...
    Plots="training-progress", ...
    Verbose=0);


net = trainNetwork(dsTrain,lgraph,options);


%% Validate net

% [X1Test,TTest,X2Test] = digitTest4DArrayData;
% dsX1Test = arrayDatastore(X1Test,IterationDimension=4);
% dsX2Test = arrayDatastore(X2Test);
% dsTest = combine(dsX1Test,dsX2Test);
% 
% YTest = classify(net,dsTest);
% 
% figure(3)
% clf
% confusionchart(TTest,YTest)
% 
% accuracy = mean(YTest == TTest);
% 
% idx = randperm(size(X1Test,4),9);
% figure(4)
% tiledlayout(3,3)
% for i = 1:9
%     nexttile
%     I = X1Test(:,:,:,idx(i));
%     imshow(I)
% 
%     label = string(YTest(idx(i)));
%     title("Predicted Label: " + label)
% end

%%
disp('multimodal')




