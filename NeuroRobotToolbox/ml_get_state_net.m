


%% Hardcoded image size
imdim = 224;


%% Get labels
labels = folders2labels(strcat(workspace_dir_name, net_name, '\'));
labels = unique(labels);
n_unique_states = length(labels);
disp(horzcat('Training detector net for ', num2str(n_unique_states), ' states'))


%% Save labels
save(strcat(nets_dir_name, net_name, '-labels'), 'labels')


%%
axes(ml_out1)
cla
tx6 = text(0.03, 0.5, horzcat('training convnet on ', num2str(n_unique_states), ' states'));
drawnow


%% Train classifier net
classifier_ds = imageDatastore(strcat(workspace_dir_name, net_name, '\'), 'FileExtensions', '.png', 'IncludeSubfolders', true, 'LabelSource','foldernames');
classifier_ds.ReadFcn = @customReadFcn; % imdim = 100

net = [
    imageInputLayer([imdim imdim 3])
    
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
    Plots=this_str, Shuffle ='every-epoch', MaxEpochs=20);

net = trainNetwork(classifier_ds, net, options);

save(strcat(nets_dir_name, net_name, '-ml'), 'net')


%% End message
tx6.String = horzcat(net_name, ' trained successfully');
drawnow

