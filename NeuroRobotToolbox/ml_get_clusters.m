


%% Cluster on similarity
n_unique_states = init_n_unique_states;
try
axes(ml_train1_status)
cla
catch
end

tx3 = text(0.03, 0.5, 'Clustering...', 'FontSize', bfsize + 4);
drawnow
disp('Clustering... ')

figure(10)
clf

dists = pdist(xdata, 'correlation');
links = linkage(dists, 'weighted');
group_inds = cluster(links,'MaxClust', n_unique_states);

clf
[~, ~, o] = dendrogram(links, 0);
close(10)

try
axes(im_ax1)
cla
imagesc(xdata(o, o), [0 0.5])
title('Clustered similarity scores')
catch
end

%% Remove small groups
try
axes(ml_train1_status)
cla
tx3 = text(0.03, 0.5, 'Removing small clusters...', 'FontSize', bfsize + 4);
drawnow
catch
end

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
try
this_msg = horzcat('N unique states: ', num2str(n_unique_states));
disp(this_msg)
tx3.String = this_msg;
drawnow
catch
end

