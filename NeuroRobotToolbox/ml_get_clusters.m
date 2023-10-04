
%% Cluster on similarity
n_unique_states = init_n_unique_states;
axes(ml_out1)
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
title('Similarity matrix (sorted)')


%% Remove small groups
axes(ml_out1)
cla
tx3 = text(0.03, 0.5, horzcat('removing small clusters...'));
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
