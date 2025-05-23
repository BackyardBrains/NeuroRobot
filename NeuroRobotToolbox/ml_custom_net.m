

%%
disp('Loading labeled data')
load(horzcat(dataset_dir_name, 'robots.mat'))


%%
disp('Creating training data')
trainingData = objectDetectorTrainingData(gTruth);


%%
disp('Loading network')
load(horzcat(nets_dir_name, 'this_alexnet'))
% net = alexnet;

% net = [imageInputLayer([ml_h ml_w 3])
%         convolution2dLayer(3,xyo_l1)
%         batchNormalizationLayer
%         reluLayer    
%         maxPooling2dLayer(2,'Stride',2)  
%         convolution2dLayer(3,xyo_l2)
%         batchNormalizationLayer
%         reluLayer    
%         maxPooling2dLayer(2,'Stride',2)
%         convolution2dLayer(3,xyo_l3)
%         batchNormalizationLayer
%         reluLayer    
%         maxPooling2dLayer(2,'Stride',2)        
%         fullyConnectedLayer(xyo_l5)
%         batchNormalizationLayer
%         reluLayer
%         fullyConnectedLayer(xyo_l6)
%         batchNormalizationLayer
%         reluLayer        
%         fullyConnectedLayer(2)
%         softmaxLayer()
%         classificationLayer()];


%%
options = trainingOptions('sgdm', 'MiniBatchSize', ml_batch, ...
    'InitialLearnRate', ml_rate, 'MaxEpochs', ml_epochs, ...
    'executionenvironment', 'auto', 'verbosefrequency', 100);


disp('Training RCNN')
rcnn = trainRCNNObjectDetector(trainingData, net, options);
save(horzcat(nets_dir_name, 'rcnn'), 'rcnn')
disp(horzcat('Done. Trained network saved to ', nets_dir_name))


disp('Training Fast RCNN')
rcnn = trainFastRCNNObjectDetector(trainingData, net, options);
save(horzcat(nets_dir_name, 'frcnn'), 'rcnn')
disp(horzcat('Done. Trained network saved to ', nets_dir_name))


disp('Training Faster RCNN')
rcnn = trainFasterRCNNObjectDetector(trainingData, net, options);
save(horzcat(nets_dir_name, 'ffrcnn'), 'rcnn')
disp(horzcat('Done. Trained network saved to ', nets_dir_name))


disp('Custom training complete.')

