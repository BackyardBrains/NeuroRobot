

%% Get net name
net_name = 'statenet';
% unsup_edit2.String
% if isempty(net_name) || strcmp(net_name, 'Enter state net name here')
%     unsup_edit2.BackgroundColor = [1 0 0];
%     pause(0.5)
%     unsup_edit2.BackgroundColor = [0.94 0.94 0.94];
%     error('Set state net name')
% end


%% Create datasets for training nets
axes(ml_out1)
cla
tx5 = text(0.03, 0.5, horzcat('creating training datasets...'));
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
tx5.String = horzcat('created ', num2str(n_unique_states), ' state folders. visualizing...');
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
pause(2)


%% Output
axes(ml_out1)
tx5.String = horzcat(num2str(n_unique_states), ' state folders created and visualized');
drawnow
