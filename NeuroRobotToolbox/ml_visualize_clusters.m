
%% Prepare figure
fig_ml = figure(4);
clf
set(fig_ml, 'NumberTitle', 'off', 'Name', 'Visualize Clusters')
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
