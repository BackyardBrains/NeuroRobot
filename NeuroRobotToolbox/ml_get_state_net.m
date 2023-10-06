


%% Hardcoded image size
% imdim = 224;
imdim_h = 227;
imdim_w = 302;


%% Get labels
labels = folders2labels(strcat(workspace_dir_name, net_name, '\'));
labels = unique(labels);
n_unique_states = length(labels);
disp(horzcat('Training pattern recogniztion net for ', num2str(n_unique_states), ' states'))


%% Save labels
save(strcat(nets_dir_name, net_name, '-labels'), 'labels')


%%
axes(ml_train1_status)
cla
tx6 = text(0.03, 0.5, horzcat('training pattern recognition net on ', num2str(n_unique_states), ' states'));
drawnow


%% Train classifier net
classifier_ds = imageDatastore(strcat(workspace_dir_name, net_name, '\'), 'FileExtensions', '.png', 'IncludeSubfolders', true, 'LabelSource','foldernames');
classifier_ds.ReadFcn = @customReadFcn; % imdim = 100

net = [
    imageInputLayer([imdim_h imdim_w 3])
    
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    fullyConnectedLayer(n_unique_states)
    softmaxLayer
    classificationLayer];

if isdeployed
    this_str = 'none';
else
    this_str = 'training-progress';
end
options = trainingOptions('adam', 'ExecutionEnvironment', 'auto', ...
    MiniBatchSize = 64, Plots=this_str, Shuffle ='every-epoch', ...
    MaxEpochs=30, VerboseFrequency= 1);

net = trainNetwork(classifier_ds, net, options);

save(strcat(nets_dir_name, net_name, '-ml'), 'net')


%% End message
tx6.String = horzcat(net_name, ' trained successfully');
drawnow

