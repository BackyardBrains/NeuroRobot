
%% Hippocampus

clear
clc

imdim = 100;
data_dir_name = 'C:\Users\Christopher Harris\Data_2\';
tuple_dir_name = 'Tuples1\';

image_ds = imageDatastore(strcat(data_dir_name, tuple_dir_name), 'FileExtensions', '.png');
image_ds.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
nimages = length(image_ds.Files);

nsmall = 2000;
nmedium = 5000;
image_ds_small = subset(image_ds, randsample(nimages, nsmall));
image_ds_medium = subset(image_ds, randsample(nimages, nmedium));

image_ds_small.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
image_ds_medium.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually

bag = bagOfFeatures(image_ds_small, 'treeproperties', [1 500]);
save(strcat(data_dir_name, 'bag'), 'bag')

imageIndex = indexImages(image_ds_medium, bag);
save(strcat(data_dir_name, 'imageIndex'), 'imageIndex')
load(strcat(data_dir_name, 'imageIndex'))

%% Get image similarity matrix
queryROI = [1, 1, imdim - 1, imdim - 1];
xdata = zeros(nmedium, nmedium);
for nimage = 1:nmedium
    if ~rem(nimage, round(nmedium/10))
        disp(horzcat('Processing tuple ', num2str(nimage), ' of ', num2str(nmedium)))
    end
    img = readimage(image_ds_medium, nimage);
    [inds,similarity_scores] = retrieveImages(img, imageIndex, 'Metric', 'L1', 'ROI', queryROI, 'NumResults', Inf);
    xdata(nimage, inds) = similarity_scores;
end
save(strcat(data_dir_name, 'xdata'), 'xdata', '-v7.3')


%% Plot similarity matrix
figure(1)
clf
subplot(1,2,1)
imagesc(xdata)
colorbar
title('xdata')
subplot(1,2,2)
histogram(xdata(:))
set(gca, 'yscale', 'log')
title('xdata histogram')


%% Group images
n_unique_states = 50;
group_inds = kmeans(xdata, n_unique_states);
% group_inds = kmedoids(xdata, n_unique_states);

noise_group = mode(group_inds);
disp(horzcat('noise group: ', num2str(noise_group)))
disp(horzcat('frames in noise group: ', num2str(sum(group_inds == noise_group))))

% inds3 = dbscan(xdata, 0.25, 5);
% unique_inds = unique(inds3);
% unique_inds(unique_inds == -1) = [];
% n_unique_states = length(unique_inds);
% disp(horzcat('nclusters: ', num2str(n_unique_states)))

figure(2)
clf
histogram(group_inds, 'binwidth', 0.25)
title('States')
xlabel('State')
ylabel('Count')
set(gca, 'yscale', 'log')


%% Remove noise group and small groups
min_size = 60;
n_unique_states = length(unique(group_inds));
state_info = zeros(n_unique_states, 1);
state_inds = zeros(n_unique_states, min_size);
for nstate = 1:n_unique_states
    these_inds = find(group_inds == nstate);
    if length(these_inds) >= min_size
        state_info(nstate, 1) = 1;
        state_inds(nstate, :) = randsample(these_inds, min_size);
    end
end

noise_group = mode(group_inds);
% state_inds(noise_group,:) = [];
% state_info(noise_group) = [];
state_inds(state_info == 0, :) = [];
state_info(state_info == 0) = [];
n_unique_states = sum(state_info);
disp(horzcat('n unique states: ', num2str(n_unique_states)))


%% Create ground truth image folders
for nstate = 1:n_unique_states
    disp(horzcat('Processing state ', num2str(nstate)))
    if nstate >= 100
        this_dir = strcat('state_', num2str(nstate));
    elseif nstate >= 10
        this_dir = strcat('state_0', num2str(nstate));
    else
        this_dir = strcat('state_00', num2str(nstate));
    end
    mkdir(strcat(data_dir_name, 'Classifier\', this_dir))
    for nimage = 1:min_size
        this_ind = state_inds(nstate, nimage);
        this_im = imread(imageIndex.ImageLocation{this_ind});
        fname = strcat(data_dir_name, 'Classifier\', this_dir, '\', 'im', num2str(this_ind), '.png');
        imwrite(this_im, fname);
    end
end


%% Train classifier net
classifier_ds = imageDatastore(strcat(data_dir_name, 'Classifier\'), 'FileExtensions', '.png', 'IncludeSubfolders', true, 'LabelSource','foldernames');
classifier_ds.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually

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
    
    fullyConnectedLayer(n_unique_states)
    softmaxLayer
    classificationLayer];

options = trainingOptions('adam', 'ExecutionEnvironment', 'auto', ...
    Plots="training-progress", Shuffle ='every-epoch', MaxEpochs=15);

net = trainNetwork(classifier_ds, net, options);

save(strcat(data_dir_name, 'randomwalk_net'), 'net')


