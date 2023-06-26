

close all
clear


%% Get data

[X1Train,TTrain,X2Train] = digitTrain4DArrayData;
numObservationsTrain = numel(TTrain);

% rand_idx = randperm(numObservationsTrain,numObservationsTrain);
% TTrain = TTrain(rand_idx);

dsX1Train = arrayDatastore(X1Train,IterationDimension=4);   % images (hand-drawn digits)
dsX2Train = arrayDatastore(X2Train);                        % numbers (angles)
dsTTrain = arrayDatastore(TTrain);                          % labels (0-9)
dsTrain = combine(dsX1Train,dsX2Train,dsTTrain);            % combined

figure(1)
tiledlayout("flow");
idx = randperm(numObservationsTrain,20);
for i = 1:numel(idx)
    nexttile
    imshow(X1Train(:,:,:,idx(i)))
    title("Angle: " + X2Train(idx(i)))
end


%% Initialize net
[h,w,numChannels,numObservations] = size(X1Train);
numFeatures = 1;
numClasses = numel(categories(TTrain));

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


%% Train net
options = trainingOptions("sgdm", ...
    MaxEpochs=15, ...
    InitialLearnRate=0.01, ...
    Plots="training-progress", ...
    Verbose=0);

net = trainNetwork(dsTrain,lgraph,options);


%% Validate net

[X1Test,TTest,X2Test] = digitTest4DArrayData;
dsX1Test = arrayDatastore(X1Test,IterationDimension=4);
dsX2Test = arrayDatastore(X2Test);
dsTest = combine(dsX1Test,dsX2Test);

YTest = classify(net,dsTest);

figure(3)
clf
confusionchart(TTest,YTest)

accuracy = mean(YTest == TTest);

idx = randperm(size(X1Test,4),9);
figure(4)
tiledlayout(3,3)
for i = 1:9
    nexttile
    I = X1Test(:,:,:,idx(i));
    imshow(I)

    label = string(YTest(idx(i)));
    title("Predicted Label: " + label)
end


