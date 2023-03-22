
imdim = 100;

%% Save labels
labels = folders2labels(strcat(workspace_dir_name, net_name, '\'));
labels = unique(labels);
n_unique_states = length(labels);
disp(horzcat('Training detector of ', num2str(n_unique_states), ' states'))
save(strcat(nets_dir_name, net_name, '-labels'), 'labels')

axes(ax6)
cla
tx6 = text(0.03, 0.5, horzcat('training convnet on ', num2str(n_unique_states), ...
    ' states (', num2str(min_size), ' images per state) ...'));
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

save(strcat(nets_dir_name, net_name, '-net'), 'net')


%% End message
tx6.String = horzcat(net_name, ' trained successfully');
drawnow
