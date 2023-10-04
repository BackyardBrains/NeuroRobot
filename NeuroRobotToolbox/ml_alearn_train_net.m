
%% Get net name
net_name = alearn_name_edit.String;
if isempty(net_name)
    alearn_name_edit.BackgroundColor = [1 0 0];
    pause(0.5)
    alearn_name_edit.BackgroundColor = [0.94 0.94 0.94];
    error('Name your associative network')
end


%% Get speed
if alearn_speed_select.Value == 1 % Slow
    alearn_speed = 1;
elseif alearn_speed_select.Value == 2 % Fast
    alearn_speed = 0.1;
end


%% Set ML parameters
nsmall = round((0.01 * ntuples + 1000) * alearn_speed);
bof_branching = round((0.01 * ntuples + 100) * alearn_speed);
nmedium = round((0.02 * ntuples + 2000) * alearn_speed);
init_n_unique_states = round(0.0001 * ntuples * alearn_speed) + 10;
min_size = round(0.0001 * ntuples * alearn_speed) + 10;

disp(horzcat('nsmall = ', num2str(nsmall)))
disp(horzcat('nmedium = ', num2str(nmedium)))
disp(horzcat('bof_branching = ', num2str(bof_branching)))
disp(horzcat('init_n_unique_states = ', num2str(init_n_unique_states)))
disp(horzcat('min_size = ', num2str(min_size)))


%% Get features and similarity scores
axes(alearn_train_status_ax)
cla

this_msg = horzcat('Finding features...');
tx2 = text(0.03, 0.5, this_msg);
drawnow
disp(this_msg)

small_inds = randsample(ntuples, nsmall);
medium_inds = randsample(ntuples, nmedium);
image_ds_small = subset(image_ds, small_inds);
image_ds_medium = subset(image_ds, medium_inds);
image_ds_small.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
image_ds_medium.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually

ps = parallel.Settings;
ps.Pool.AutoCreate = false;
ps.Pool.IdleTimeout = Inf;

bag = bagOfFeatures(image_ds_small, 'treeproperties', [2 bof_branching]);

this_msg = 'Creating image index...';
tx2.String = this_msg;
drawnow
disp(this_msg)
imageIndex = indexImages(image_ds_medium, bag);

this_msg = 'Getting similarity matrix...';
tx2.String = this_msg;
drawnow
disp(this_msg)

xdata = zeros(nmedium, nmedium);

for ntuple = 1:nmedium
    
    if ~rem(ntuple, round(nmedium/10))
        disp(horzcat('Processing tuple ', num2str(ntuple), ' of ', num2str(nmedium)))
    end
    img = readimage(image_ds_medium, ntuple);
    [inds,similarity_scores] = retrieveImages(img, imageIndex, 'Metric', 'L1', 'NumResults', Inf);
%     [inds,similarity_scores] = retrieveImages(img, imageIndex, 'Metric', 'cosine', 'NumResults', Inf);
    xdata(ntuple, inds) = similarity_scores;

end

avg_sim = mean(xdata(:));
this_msg = horzcat('Avg. similarity = ', num2str(avg_sim));
disp(this_msg)
tx2.String = horzcat(this_msg);
drawnow


%% Plot similarity matrix
axes(im_ax1)
histogram(xdata(:))
set(gca, 'yscale', 'log')
title('Image similarity scores')

drawnow


%% Cluster on similarity
n_unique_states = init_n_unique_states;
axes(alearn_train_status_ax)
cla

tx3 = text(0.03, 0.5, horzcat('Clustering...'));
drawnow
disp('Clustering... ')

% n_unique_states = 100;
% group_inds = kmeans(xdata, n_unique_states);

dists = pdist(xdata, 'correlation');
links = linkage(dists, 'weighted');
group_inds = cluster(links,'MaxClust', n_unique_states);

figure(10)
[~, ~, o] = dendrogram(links, 0);
close(10)

axes(im_ax1)
cla
imagesc(xdata(o, o), [0 1])
set(gca, 'xtick', [], 'ytick', [])
title('Sorted similarity matrix')


%% Remove small groups
axes(alearn_train_status_ax)
cla
tx3 = text(0.03, 0.5, horzcat('Removing small clusters...'));
drawnow

n_unique_states = length(unique(group_inds));
state_info = zeros(n_unique_states, 3);
state_inds = zeros(n_unique_states, min_size);
for nstate = 1:n_unique_states
    these_inds = find(group_inds == nstate);
    if length(these_inds) >= min_size
        these_inds_subset = randsample(these_inds, min_size);
        state_inds(nstate, :) = these_inds_subset;
        state_info(nstate, 1) = 1;
    else
        group_inds(group_inds == nstate) = 0;
    end
end

state_inds(state_info(:,1)==0, :) = [];
state_info(state_info(:,1)==0, :) = [];

n_unique_states = sum(state_info(:,1));
disp(horzcat('N unique states: ', num2str(n_unique_states)))

cla
tx3 = text(0.03, 0.5, horzcat('n unique states = ', num2str(n_unique_states)));
drawnow



%% Get inter-state similarity
axes(alearn_train_status_ax)
cla

tx4 = text(0.03, 0.5, horzcat('Getting inter-state similarities...'));
drawnow

inter_state_similarity = zeros(n_unique_states, n_unique_states);
for nstate = 1:n_unique_states
    these_inds = state_inds(nstate, :);

    for nstate2 = 1:n_unique_states
        these_inds2 = state_inds(nstate2, :);
        vals = xdata(these_inds,these_inds2);
%         vals(vals == 1) = nan;
        inter_state_similarity(nstate, nstate2) = mean(vals(:), 'omitnan');
    end

end

avg_inter = mean(inter_state_similarity(:));
tx4.String = horzcat('avg. inter-state = ', num2str(avg_inter), ', getting intra-state...');
drawnow


%% Get intra-state similarity
intra_state_similarity = zeros(n_unique_states, 1);
for nstate = 1:n_unique_states
    these_inds = state_inds(nstate, :);

    vals = xdata(these_inds,these_inds);
%     vals(vals == 1) = nan;
    intra_state_similarity(nstate) = mean(vals(:), 'omitnan');

end

prc25 = prctile(intra_state_similarity, 25);

avg_intra = mean(intra_state_similarity);
tx4.String = horzcat('avg. inter-state = ', num2str(avg_inter), ...
    ', avg. intra-state = ', num2str(avg_intra));
drawnow


%% Create datasets for training nets
axes(alearn_train_status_ax)
cla
tx5 = text(0.03, 0.5, horzcat('Creating training datasets...'));
drawnow

try
    rmdir(strcat(workspace_dir_name, net_name), 's')
catch
    disp(horzcat('Could not find or delete any previous training data for ', net_name))
end

n_unique_states = sum(state_info(:,1));
disp(horzcat('n unique states: ', num2str(n_unique_states)))

for nstate = 1:n_unique_states
    disp(horzcat('Processing state ', num2str(nstate)))
    if nstate >= 100
        this_dir = strcat('state_', num2str(nstate));
    elseif nstate >= 10
        this_dir = strcat('state_0', num2str(nstate));
    else
        this_dir = strcat('state_00', num2str(nstate));
    end
    mkdir(strcat(workspace_dir_name, net_name, '\', this_dir))
    for nimage = 1:min_size
        this_ind = state_inds(nstate, nimage);
        this_im = imread(imageIndex.ImageLocation{this_ind});
        fname = strcat(workspace_dir_name, net_name, '\', this_dir, '\', 'im', num2str(this_ind), '.png');
        imwrite(this_im, fname);
    end
end


%% Get labels
labels = folders2labels(strcat(workspace_dir_name, net_name, '\'));
labels = unique(labels);
n_unique_states = length(labels);
disp(horzcat('n unique states = ', num2str(n_unique_states)))


%% Output
tx5.String = horzcat('Visualizing ', num2str(n_unique_states), ' states');
drawnow


%% Prepare figure
fig_ml = figure(4);
clf
set(fig_ml, 'NumberTitle', 'off', 'Name', 'States')
set(fig_ml, 'menubar', 'none', 'toolbar', 'none')
fig_pos = get(0, 'screensize') + [0 49 0 -71];
set(fig_ml, 'position', fig_pos, 'color', fig_bg_col) 


%% Visualize
data = zeros(n_unique_states, 1);
x = ceil(sqrt(n_unique_states));
for nstate = 1:n_unique_states
    these_inds = state_inds(nstate, :);
    these_scores = mean(xdata(these_inds,these_inds), 2);
    [i, j] = max(these_scores);
    subplot(x, x, nstate)
    img = readimage(image_ds_medium, these_inds(j));
    image(img)
    set(gca, 'xtick', [], 'ytick', [])
    mean_score = mean(these_scores);
    label_str = char(labels(nstate));
    label_str(label_str == '_') = [];
    title(horzcat('state: ', num2str(nstate), ', s: ', num2str(mean_score)))
    data(nstate) = mean_score;
end
drawnow
saveas(fig_ml, horzcat(nets_dir_name, net_name, '-examples.fig'))


%% Output
axes(alearn_train_status_ax)
tx5.String = horzcat(num2str(n_unique_states), ' state folders created and visualized');
drawnow


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
axes(alearn_train_status_ax)
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
tx6.String = horzcat('Trained ', net_name, ' successfully');
drawnow

