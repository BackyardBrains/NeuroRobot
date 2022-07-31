
%% New hippocampus code

clear
clc

nmatches = Inf;
queryROI = [1 1 226 126];
this_th = 0.995;

tuples_dir_name = 'C:\Users\Christopher Harris\RandomWalkData\Rec_1\';
image_ds = imageDatastore(tuples_dir_name, 'FileExtensions', '.png', 'IncludeSubfolders', true);
% imageIndex = indexImages(image_ds);
% imageIndex.MatchThreshold = 0;
load('image_ds')
load('imageIndex')
nimages = length(imageIndex.ImageLocation);
removeImages(imageIndex, ((nimages/2)+1):nimages)

%%
ntuples = length(imageIndex.ImageLocation);
xdata = single(ntuples);
for ntuple = 1:ntuples
    disp(horzcat('Processing tuple ', num2str(ntuple), ' of ', num2str(ntuples)))
    img = readimage(image_ds, ntuple);
    [inds,similarity_scores] = retrieveImages(img, imageIndex, 'Metric', 'L1', 'ROI', queryROI);
%     inds(similarity_scores < this_th) = [];
%     similarity_scores(similarity_scores < this_th) = 0;
%     similarity_scores(similarity_scores > 0) = 1;
    xdata(ntuple, inds) = similarity_scores;
end
% xdata(:,(ntuples+1):end) = [];
save('xdata', 'xdata')
% load('xdata')

%%
% n_unique_states = 10;
% states = clusterdata(xdata,'SaveMemory', 'on', 'metric', 'euclidian', 'linkage', 'centroid', 'Maxclust',n_unique_states); 

n_unique_states = 50;
[states, cstates] = kmeans(xdata, n_unique_states);

% inds3 = dbscan(xdata, 0.25, 5);
% unique_inds = unique(inds3);
% unique_inds(unique_inds == -1) = [];
% n_unique_states = length(unique_inds);
% disp(horzcat('nclusters: ', num2str(n_unique_states)))

figure(1)
clf
histogram(states, 'binwidth', 0.25)
title('States')
xlabel('State')
ylabel('Count')

% %%
% for ntuple = 1:n_unique_states
%     figure(10+ntuple)
%     clf
%     x = find(states == ntuple);
%     if length(x) > 50 
%         x = randsample(x, 50);
%     end
%     montage(imageIndex.ImageLocation(x))
%     pause
%     close(10+ntuple)
% end

%% Create new database
min_size = 20;
state_info = zeros(n_unique_states, 1);
state_inds = zeros(n_unique_states, min_size);
for nstate = 1:n_unique_states
    these_inds = find(states == nstate);
    if length(these_inds) >= min_size
        state_info(nstate, 1) = 1;
        state_inds(nstate, :) = randsample(these_inds, min_size);
    end
end
noise_group = mode(states)
state_inds(noise_group,:) = [];
state_info(noise_group) = [];
state_inds(state_info == 0, :) = [];
state_info(state_info == 0) = [];
n_unique_states = sum(state_info)

this_root = '.\Data_1\Rec_3\';
for nstate = 1:n_unique_states
    disp(horzcat('Processing state ', num2str(nstate)))
    if nstate >= 100
        this_dir = strcat('state_', num2str(nstate));
    elseif nstate >= 10
        this_dir = strcat('state_0', num2str(nstate));
    else
        this_dir = strcat('state_00', num2str(nstate));
    end
    mkdir(strcat(this_root, this_dir))
    for ntuple = 1:min_size
        this_ind = state_inds(nstate, ntuple);
        this_im = imread(imageIndex.ImageLocation{this_ind});
        fname = strcat(this_root, this_dir, '\', 'im', num2str(this_ind), '.png');
        imwrite(this_im, fname);
    end
end
