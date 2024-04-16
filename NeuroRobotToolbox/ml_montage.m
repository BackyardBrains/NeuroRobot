
fig_ml = figure(4);
clf
set(fig_ml, 'NumberTitle', 'off', 'Name', 'States')
set(fig_ml, 'toolbar', 'none')
set(fig_ml, 'position', [175 70 1200 720], 'color', fig_bg_col) 

x = ceil(sqrt(n_unique_states));
for nstate = 1:n_unique_states
    these_inds = state_inds(nstate, :);
    these_scores = mean(xdata(these_inds,these_inds), 2); % Assuming you still need scores for something else
    subplot(x, x, nstate)
    ninds = length(these_inds);
    rand_inds = randsample(these_inds, 6);
    this_ds = subset(image_ds_medium, rand_inds);
    montage(this_ds)
    set(gca, 'xtick', [], 'ytick', [])
    mean_score = mean(these_scores);
    label_str = char(labels(nstate));
    label_str(label_str == '_') = ' ';
    title(horzcat('state: ', num2str(nstate), ', s: ', num2str(mean_score)))
end
drawnow
title(state_net_name)
