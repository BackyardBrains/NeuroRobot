


%% Get labels
labels = folders2labels(strcat(workspace_dir_name, state_net_name, '\'));
labels = unique(labels);
n_unique_states = length(labels);
disp(horzcat('Training pattern recogniztion net for ', num2str(n_unique_states), ' states'))


%% Save labels
save(strcat(nets_dir_name, state_net_name, '-labels'), 'labels')


%%
try
axes(ml_train1_status)
cla
tx6 = text(0.03, 0.5, horzcat('training pattern recognition net on ', ...
    num2str(n_unique_states), ' states'), 'FontSize', bfsize + 4);
drawnow
catch
end


%% Train classifier net
classifier_ds = imageDatastore(strcat(workspace_dir_name, state_net_name, '\'), 'FileExtensions', '.png', 'IncludeSubfolders', true, 'LabelSource','foldernames');
% classifier_ds.ReadFcn = @customReadFcn; % imdim = 100

net = [
    imageInputLayer([imdim_h imdim_w 3])
    
    convolution2dLayer(3,ml_l1,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,ml_l2,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,ml_l3,'Padding','same')
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
    MiniBatchSize=ml_bs, Plots=this_str, Shuffle ='every-epoch', ...
    MaxEpochs=ml_me, VerboseFrequency= 1);

net = trainNetwork(classifier_ds, net, options);

save(strcat(nets_dir_name, state_net_name, '-ml'), 'net')


%% End message
try
tx6.String = horzcat(state_net_name, ' trained successfully');
drawnow
catch
end

