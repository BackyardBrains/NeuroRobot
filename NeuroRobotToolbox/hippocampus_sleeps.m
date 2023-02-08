    
%% Hippocampus

% close all
% clear


imdim = 227;
localdata_dir_name = 'C:\Users\Christopher Harris\Dataset2a\';
% localdata_dir_name = 'C:\Users\Christopher Harris\NeuroRobot - Super Hot\Datasets\Recordings\';
shared_data_dir_name = '.\Brains\';
% rec_dir_name = 'PreTraining\';
rec_dir_name = '';
nsmall = 5000;
nmedium = 10000;

image_ds = imageDatastore(strcat(localdata_dir_name, rec_dir_name), 'FileExtensions', '.png', 'IncludeSubfolders', 1);
image_ds.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually - This is where some images get saved small
serial_dir = dir(fullfile(strcat(localdata_dir_name, rec_dir_name), '**\*serial_data.mat'));
torque_dir = dir(fullfile(strcat(localdata_dir_name, rec_dir_name), '**\*torques.mat'));

save(strcat(localdata_dir_name, 'image_ds'), 'image_ds')
save(strcat(localdata_dir_name, 'serial_dir'), 'serial_dir')
save(strcat(localdata_dir_name, 'torque_dir'), 'torque_dir')

nimages = length(image_ds.Files);
ndists = size(serial_dir, 1);
ntorques = size(torque_dir, 1);
ntuples = nimages/2;
disp(horzcat('nimages: ', num2str(nimages)))
disp(horzcat('ndists:',  num2str(ndists)))
disp(horzcat('ntorques:' , num2str(ntorques)))
disp(horzcat('ntuples: ', num2str(ntuples)))

small_inds = randsample(ntuples, nsmall);
medium_inds = randsample(ntuples, nmedium);
image_ds_small = subset(image_ds, small_inds*2);
image_ds_medium = subset(image_ds, medium_inds*2);
image_ds_small.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
image_ds_medium.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually

ps = parallel.Settings;
ps.Pool.AutoCreate = false;
ps.Pool.IdleTimeout = Inf;

bag = bagOfFeatures(image_ds_small, 'treeproperties', [1 200]);
imageIndex = indexImages(image_ds_medium, bag);

% save(strcat(localdata_dir_name, 'bag'), 'bag')
% save(strcat(localdata_dir_name, 'imageIndex'), 'imageIndex')

get_dists
get_image_crosscorr

% save(strcat(localdata_dir_name, 'xdata_L1'), 'xdata', '-v7.3')
% save(strcat(localdata_dir_name, 'xdata_cosine'), 'xdata', '-v7.3')

% ydata = zeros(nmedium, nmedium);
% for ntuple = 1:nmedium
%     dist1 = dists(ntuple);
%     for ntuple2 = 1:nmedium
%         dist2 = dists(ntuple2);
%         if dist1 == 0 && dist2 == 0
%             dist_match = 1;
%         elseif dist1 > 0 && dist2 > 0
%             dist_match = 1;
%         else
%             dist_match = 0;
%         end     
%         ydata(ntuple, ntuple2) = dist_match;
%     end
% end
% 
% zdata = xdata .* ydata;


%% Plot similarity matrix
disp('Plotting similarity matrix...')
figure(2)
clf
set(gcf, 'color', 'w')
subplot(1,2,1)
imagesc(xdata)
colorbar
title('zdata')
subplot(1,2,2)
histogram(xdata(:))
set(gca, 'yscale', 'log')
title('zdata histogram')

% xdata(xdata<0.5) = 0;


%% Group images
disp('Clustering...')
n_unique_states = 100;
dists = pdist(xdata,'euclidean');
links = linkage(dists,'average');
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
min_size = 50;
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

figure(4)
clf
h = histogram(state_entropy, 'binwidth', 0.005);
hold on
plot([th th], [0 max(h.Values)], 'linewidth', 2, 'color', 'r')
title('Similarity scores')


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
        mkdir(strcat(localdata_dir_name, 'Net1\', this_dir))
        for nimage = 1:min_size
            this_ind = state_inds(nstate, nimage);
            this_im = imread(imageIndex.ImageLocation{this_ind});
            fname = strcat(localdata_dir_name, 'Net1\', this_dir, '\', 'im', num2str(this_ind), '.png');
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

n_unique_states = length(state_entropy);
disp(horzcat('N unique states: ', num2str(n_unique_states)))

% %% Prepare categories
% labels = folders2labels(strcat(localdata_dir_name, 'Classifier\'));
% labels = unique(labels);
% save(strcat(shared_data_dir_name, 'livingroom_labels'), 'labels')
% n_unique_states = length(labels);
% disp(horzcat('N unique states: ', num2str(n_unique_states)))


%% Train classifier net
classifier_ds = imageDatastore(strcat(localdata_dir_name, 'Net1\'), 'FileExtensions', '.png', 'IncludeSubfolders', true, 'LabelSource','foldernames');
classifier_ds.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually

net = [
    imageInputLayer([imdim imdim 3])
    
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,64,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,64,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,64,'Padding','same')
    batchNormalizationLayer
    reluLayer    
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,64,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    fullyConnectedLayer(n_unique_states)
    softmaxLayer
    classificationLayer];

options = trainingOptions('adam', 'ExecutionEnvironment', 'auto', ...
    Plots="training-progress", Shuffle ='every-epoch', MaxEpochs=5);

net = trainNetwork(classifier_ds, net, options);

% save(strcat(shared_data_dir_name, 'Net1_net'), 'net')
save(strcat(localdata_dir_name, 'Net1_net'), 'net')



