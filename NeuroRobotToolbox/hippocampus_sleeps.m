    
%% Hippocampus

clear
clc

imdim = 100;
localdata_dir_name = 'C:\Users\Christopher Harris\Dataset 1\';
shared_data_dir_name = '.\Brains\';
rec_dir_name = 'PreTraining\';

nsmall = 10000;
nmedium = 20000;

hippocampus_associator

disp('Re-loading databases and matrices...')
load(strcat(localdata_dir_name, 'image_ds'))
load(strcat(localdata_dir_name, 'bag'))
load(strcat(localdata_dir_name, 'imageIndex'))

load(strcat(localdata_dir_name, 'xdata_L1'))
% load(strcat(localdata_dir_name, 'xdata_cosine'))


%% Plot similarity matrix
disp('Plotting similarity matrix...')
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

% xdata(xdata<0.5) = 0;


%% Group images
disp('Clustering...')
n_unique_states = 500;
dists = pdist(xdata,'euclidean');
links = linkage(dists,'ward');
group_inds = cluster(links,'MaxClust',n_unique_states);
save(strcat(localdata_dir_name, 'group_inds'), 'group_inds', '-v7.3')

figure(2)
clf
subplot(1,2,1)
[~, ~, o] = dendrogram(links, 0);
subplot(1,2,2)
imagesc(xdata(o, o))
colorbar

load(strcat(localdata_dir_name, 'group_inds'))
noise_group = mode(group_inds);
disp(horzcat('noise group: ', num2str(noise_group)))
disp(horzcat('frames in noise group: ', num2str(sum(group_inds == noise_group))))


%% Optional: Remove small groups and/or noise group
disp('Prune clusters...')
min_size = 25;
n_unique_states = length(unique(group_inds));
state_info = zeros(n_unique_states, 3);
state_inds = zeros(n_unique_states, min_size);
for nstate = 1:n_unique_states
    these_inds = find(group_inds == nstate);
    if length(these_inds) >= min_size
        these_inds_subset = randsample(these_inds, min_size);
        state_inds(nstate, :) = these_inds_subset;
        state_info(nstate, 1) = 1;
    end
end

noise_group = mode(group_inds);
disp(horzcat('noise group: ', num2str(noise_group)))
% state_inds(noise_group, :) = [];
% state_info(noise_group, :) = [];

state_inds(state_info(:,1)==0, :) = [];
state_info(state_info(:,1)==0, :) = [];

n_unique_states = sum(state_info(:,1));
disp(horzcat('N unique states: ', num2str(n_unique_states)))

figure(3)
clf
h = histogram(group_inds, 'binwidth', 0.25);
hold on
% plot([th th], [0 max(h.Values)], 'linewidth', 2, 'color', 'r')
title('States')
xlabel('State')
ylabel('Count')
set(gca, 'yscale', 'log')

%% Entropy quality check
disp('Remove high entropy clusters')
state_entropy = zeros(n_unique_states, 1);
for nstate = 1:n_unique_states
    these_inds = state_inds(nstate, :);
    these_scores = mean(xdata(these_inds,these_inds), 2);
    state_entropy(nstate) = mean(these_scores);
    [i, j] = max(these_scores);
    state_info(nstate, 2) = i;
    state_info(nstate, 3) = these_inds(j);    
end

th = prctile(state_entropy, 25);
% th = 0;

figure(4)
clf
h = histogram(state_entropy, 'binwidth', 0.005);
hold on
plot([th th], [0 max(h.Values)], 'linewidth', 2, 'color', 'r')
title('Inverse entropy of states')


%%
n_unique_states = sum(state_info(:,1));
disp(horzcat('n unique states: ', num2str(n_unique_states)))
for nstate = 1:n_unique_states
    
    if state_entropy(nstate) > th
        disp(horzcat('Processing state ', num2str(nstate)))
        if nstate >= 100
            this_dir = strcat('state_', num2str(nstate));
        elseif nstate >= 10
            this_dir = strcat('state_0', num2str(nstate));
        else
            this_dir = strcat('state_00', num2str(nstate));
        end
        mkdir(strcat(localdata_dir_name, 'Classifier\', this_dir))
        for nimage = 1:min_size
            this_ind = state_inds(nstate, nimage);
            this_im = imread(imageIndex.ImageLocation{this_ind});
            fname = strcat(localdata_dir_name, 'Classifier\', this_dir, '\', 'im', num2str(this_ind), '.png');
            imwrite(this_im, fname);
        end
        state_info(nstate, 1) = 1;
    else
        disp(horzcat('Skipping state ', num2str(nstate)))
        state_info(nstate, 1) = 0;
    end
end

state_entropy(state_info(:,1) == 0) = [];
state_info(state_info(:,1) == 0, :) = [];


%% Prepare categories
labels = folders2labels(strcat(localdata_dir_name, 'Classifier\'));
labels = unique(labels);
save(strcat(shared_data_dir_name, 'livingroom_labels'), 'labels')
n_unique_states = length(labels);
disp(horzcat('N unique states: ', num2str(n_unique_states)))


%% Train classifier net
classifier_ds = imageDatastore(strcat(localdata_dir_name, 'Classifier\'), 'FileExtensions', '.png', 'IncludeSubfolders', true, 'LabelSource','foldernames');
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

save(strcat(shared_data_dir_name, 'livingroomX_net'), 'net')




