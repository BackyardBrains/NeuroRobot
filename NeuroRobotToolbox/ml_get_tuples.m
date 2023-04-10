

%%
axes(ax7)

cla
tx7 = text(0.03, 0.5, horzcat('loading net...'));
drawnow
disp('Loading state net...')

load(strcat(nets_dir_name, net_name, '-net'))
load(strcat(nets_dir_name, net_name, '-labels'))
n_unique_states = length(labels);
disp(horzcat('n unique states: ', num2str(n_unique_states)))

tx7.String = 'indexing all data..';
drawnow

image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*.png'));
serial_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*serial_data.mat'));
torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));

ntorques = size(torque_dir, 1);
nimages = size(image_dir, 1);
ntuples = ntorques;
disp(horzcat('ntuples: ', num2str(ntuples)))


%% States
tx7.String = 'getting states..';
drawnow
% get_dists
get_states
save(horzcat(nets_dir_name, net_name, '-states'), 'states')
load(horzcat(nets_dir_name, net_name, '-states'))
disp(horzcat('n unique states: ', num2str(n_unique_states)))
ntuples = size(states, 1);
disp(horzcat('ntuples: ', num2str(ntuples)))
tx7.String = horzcat('nstates loaded: ', num2str(ntuples), ', ...');
drawnow


%% Torques
tx7.String = 'loading torques..';
drawnow
get_torques
save(horzcat(nets_dir_name, net_name, '-torque_data'), 'torque_data')
load(horzcat(nets_dir_name, net_name, '-torque_data'))
tx7.String = horzcat('ntorques loaded: ', num2str(ntuples), ' LR torque value pairs, ...');
drawnow


%% Actions
n_unique_actions = 9;
rng(1)
tx7.String = horzcat('clustering torques to into ', num2str(n_unique_actions + 1), ' unique actions...');
drawnow

actions = kmeans(torque_data, n_unique_actions);
still = torque_data(:,1) == 0 & torque_data(:,2) == 0;
disp(horzcat('n still actions: ', num2str(sum(still))))
actions(still) = n_unique_actions + 1;
if ~sum(actions == 1)
    actions = actions - 1;
end
n_unique_actions = length(unique(actions));
disp(horzcat('n unique actions: ', num2str(n_unique_actions)))

save(strcat(nets_dir_name, net_name, '-actions'), 'actions')
load(strcat(nets_dir_name, net_name, '-actions'))


%% Plot torque data with action IDs
axes(im_ax2)
cla
gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*4, torque_data(:,2)+randn(size(torque_data(:,2)))*4, actions)
hold on
for naction = 1:n_unique_actions
    mean_torque = mean(torque_data(actions == naction, :));
    text(mean_torque(1), mean_torque(2), num2str(naction))
end
axis padded
set(gca, 'yscale', 'linear')
title('Actions')
xlabel('Torque 1')
ylabel('Torque 2')


%% Get tuples
tuples = zeros(ntuples - 6, 3);
for ntuple = 6:ntuples - 1
    tuples(ntuple - 5, 1) = states(ntuple - 5);
    tuples(ntuple - 5, 2) = states(ntuple);
    tuples(ntuple - 5, 3) = actions(ntuple - 5);
end
ntuples = size(tuples, 1);


%% Lucid sleep?
% basal_ganglia_lucid


%% Output
tx7.String = 'tuples aquired successfully';
drawnow

axes(im_ax1)
cla
histogram(tuples(:,1), 'binwidth', .25)
set(gca, 'yscale', 'linear')
title('States')
xlabel('State')
ylabel('Count (ntuples)')

