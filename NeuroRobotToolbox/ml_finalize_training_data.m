

%% Create datasets for training nets
axes(ml_train1_status)
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
tx5.String = horzcat('Created ', num2str(n_unique_states), ' state folders. visualizing...');
drawnow


%% Prepare figure
fig_ml = figure(4);
clf
set(fig_ml, 'NumberTitle', 'off', 'Name', 'States')
set(fig_ml, 'toolbar', 'none')
set(fig_ml, 'position', [175 70 1200 720], 'color', fig_bg_col) 


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
axes(ml_train1_status)
tx5.String = horzcat(num2str(n_unique_states), ' state folders created and visualized');
drawnow
