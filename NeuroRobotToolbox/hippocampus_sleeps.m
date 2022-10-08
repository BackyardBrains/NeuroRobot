    
%% Hippocampus

clear
clc

imdim = 100;
data_dir_name = 'C:\Users\Christopher Harris\Dataset 1\';
rec_dir_name = 'PreTraining\';

nsmall = 2000;
nmedium = 10000;

load(strcat(data_dir_name, 'image_ds'))
load(strcat(data_dir_name, 'bag'))
load(strcat(data_dir_name, 'imageIndex'))

load(strcat(data_dir_name, 'xdata_L1'))
% load(strcat(data_dir_name, 'xdata_cosine'))

% % % image_ds = imageDatastore(strcat(data_dir_name, rec_dir_name), 'FileExtensions', '.png', 'IncludeSubfolders', 1);
% % % image_ds.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
% % % save(strcat(data_dir_name, 'image_ds'), 'image_ds')
% % % 
% % % nimages = length(image_ds.Files);
% % % disp(horzcat('N images: ', num2str(nimages)))
% % % 
% % % image_ds_small = subset(image_ds, randsample(nimages, nsmall));
% % % image_ds_medium = subset(image_ds, randsample(nimages, nmedium));
% % % 
% % % image_ds_small.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
% % % image_ds_medium.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
% % % 
% % % ps = parallel.Settings;
% % % ps.Pool.AutoCreate = false;
% % % ps.Pool.IdleTimeout = Inf;
% % % 
% % % bag = bagOfFeatures(image_ds_small, 'treeproperties', [1 500]);
% % % save(strcat(data_dir_name, 'bag'), 'bag')
% % % 
% % % imageIndex = indexImages(image_ds_medium, bag);
% % % save(strcat(data_dir_name, 'imageIndex'), 'imageIndex')
% % % 
% % % get_image_crosscorr
% % % save(strcat(data_dir_name, 'xdata_cosine'), 'xdata', '-v7.3')


%%
xdata(xdata<0.7) = 0;

%% Plot similarity matrix
figure(1)
clf
set(gcf, 'color', 'w')
subplot(1,2,1)
imagesc(xdata)
colorbar
title('xdata')
subplot(1,2,2)
histogram(xdata(:))
set(gca, 'yscale', 'log')
title('xdata histogram')


%% Group images

n_unique_states = 1000;
dists = pdist(xdata,'euclidean');
links = linkage(dists,'ward');

figure(2)
clf
subplot(1,2,1)
[~, ~, o] = dendrogram(links, nsmall);
subplot(1,2,2)
imagesc(xdata(o, o))
colorbar

group_inds = cluster(links,'MaxClust',n_unique_states);
% group_inds = clusterdata(ydata,'Linkage', 'ward', 'SaveMemory','on','Maxclust',n_unique_states);
% group_inds = kmeans(xdata, n_unique_states);
% group_inds = kmedoids(xdata, n_unique_states);
save(strcat(data_dir_name, 'group_inds'), 'group_inds', '-v7.3')
load(strcat(data_dir_name, 'group_inds'))
noise_group = mode(group_inds);
disp(horzcat('noise group: ', num2str(noise_group)))
disp(horzcat('frames in noise group: ', num2str(sum(group_inds == noise_group))))

% inds3 = dbscan(xdata, 0.25, 5);
% unique_inds = unique(inds3);
% unique_inds(unique_inds == -1) = [];
% n_unique_states = length(unique_inds);
% disp(horzcat('nclusters: ', num2str(n_unique_states)))

figure(3)
clf
histogram(group_inds, 'binwidth', 0.25)
title('States')
xlabel('State')
ylabel('Count')
set(gca, 'yscale', 'log')


%% Remove noise group and small groups
min_size = 10;
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
state_inds(noise_group,:) = [];
state_info(noise_group) = [];
state_inds(state_info == 0, :) = [];
state_info(state_info == 0) = [];
n_unique_states = sum(state_info);
disp(horzcat('n unique states: ', num2str(n_unique_states)))


%% Create ground truth image folders
get_state_entropy
for nstate = 1:n_unique_states
    disp(horzcat('Processing state ', num2str(nstate)))
    if state_entropy(nstate) > nanmedian(state_entropy) * 3    
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
end

labels = folders2labels(strcat(data_dir_name, 'Classifier\'));
labels = unique(labels);
save(strcat(data_dir_name, 'labels'), 'labels')
n_unique_states = length(labels);

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
    Plots="training-progress", Shuffle ='every-epoch', MaxEpochs=5);

net = trainNetwork(classifier_ds, net, options);

save(strcat(data_dir_name, 'dwg_net'), 'net')


