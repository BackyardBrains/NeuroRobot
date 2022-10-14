    
%% Hippocampus

clear
clc

imdim = 100;
data_dir_name = 'C:\Users\Christopher Harris\Dataset 1\';
rec_dir_name = 'PreTraining\';

nsmall = 2000;
nmedium = 10000;

hippocampus_associator

load(strcat(data_dir_name, 'image_ds'))
load(strcat(data_dir_name, 'bag'))
load(strcat(data_dir_name, 'imageIndex'))
load(strcat(data_dir_name, 'xdata_L1'))
% load(strcat(data_dir_name, 'xdata_cosine'))


%%
xdata(xdata<0.5) = 0;


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
n_unique_states = 200;
dists = pdist(xdata,'euclidean');
links = linkage(dists,'ward');
group_inds = cluster(links,'MaxClust',n_unique_states);
save(strcat(data_dir_name, 'group_inds'), 'group_inds', '-v7.3')

figure(2)
clf
subplot(1,2,1)
[~, ~, o] = dendrogram(links, nsmall);
subplot(1,2,2)
imagesc(xdata(o, o))
colorbar

load(strcat(data_dir_name, 'group_inds'))
noise_group = mode(group_inds);
disp(horzcat('noise group: ', num2str(noise_group)))
disp(horzcat('frames in noise group: ', num2str(sum(group_inds == noise_group))))

figure(3)
clf
histogram(group_inds, 'binwidth', 0.25)
title('States')
xlabel('State')
ylabel('Count')
set(gca, 'yscale', 'log')


%% Remove noise group and small groups
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
state_inds(noise_group, :) = [];
state_info(noise_group, :) = [];

state_inds(state_info(:,1)==0, :) = [];
state_info(state_info(:,1)==0, :) = [];

n_unique_states = sum(state_info(:,1));
disp(horzcat('N unique states: ', num2str(n_unique_states)))


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

figure(4)
clf
h = histogram(state_entropy, 'binwidth', 0.05);
hold on
plot([median(state_entropy) median(state_entropy)], [0 max(h.Values)], 'linewidth', 2, 'color', 'r')
title('State entropies')


%%
n_unique_states = sum(state_info(:,1));
disp(horzcat('n unique states: ', num2str(n_unique_states)))
for nstate = 1:n_unique_states
    
    if state_entropy(nstate) > median(state_entropy)    
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
        state_info(nstate, 1) = 1;
    else
        disp(horzcat('Skipping state ', num2str(nstate)))
        state_info(nstate, 1) = 0;
    end
end

state_info(state_info(:,1) == 0, :) = [];
labels = folders2labels(strcat(data_dir_name, 'Classifier\'));
labels = unique(labels);
save(strcat(data_dir_name, 'labels'), 'labels')
n_unique_states = length(labels);
disp(horzcat('N unique states: ', num2str(n_unique_states)))

save(strcat(data_dir_name, 'state_info'), 'state_info')
save(strcat(data_dir_name, 'state_inds'), 'state_inds')


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

save(strcat(data_dir_name, 'livingroom_net'), 'net')




