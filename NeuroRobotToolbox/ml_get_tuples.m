

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

tx7.String = 'indexing data..';
drawnow
disp('indexing data...')

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
disp('assembling tuples...')

get_dists
save(horzcat(nets_dir_name, net_name, '-dists'), 'dists')

get_states
save(horzcat(nets_dir_name, net_name, '-states'), 'states')


%% State expansion by dist
load(horzcat(nets_dir_name, net_name, '-dists'))
load(horzcat(nets_dir_name, net_name, '-states'))

n_unique_states = length(unique(states));
disp(horzcat('n unique states: ', num2str(n_unique_states)))
disp(horzcat('ntuples: ', num2str(ntuples)))

tx7.String = horzcat('nstates loaded: ', num2str(ntuples), ', ...');
drawnow

touches_per_state = zeros(n_unique_states, 1);
for ntuple = 1:ntuples
    if dists(ntuple) > 0 && dists(ntuple) ~= 4000
        touches_per_state(states(ntuple)) = touches_per_state(states(ntuple)) + 1;
    end
end

touch_states = find(touches_per_state > 3000);
save(horzcat(nets_dir_name, net_name, '-touch_states'), 'touch_states')

counter = 0;
for ntuple = 1:ntuples
    if sum(states(ntuple) == touch_states) && dists(ntuple) > 0 && dists(ntuple) ~= 4000
        ind = find(states(ntuple) == touch_states);
        states(ntuple) = n_unique_states + ind;
    end
end

n_unique_states = n_unique_states + length(touch_states);
disp(horzcat('n unique states: ', num2str(n_unique_states)))


%% Torques
tx7.String = 'loading torques..';
drawnow
get_torques
save(horzcat(nets_dir_name, net_name, '-torque_data'), 'torque_data')
load(horzcat(nets_dir_name, net_name, '-torque_data'))
tx7.String = horzcat('ntorques loaded: ', num2str(ntuples), ' LR torque value pairs, ...');
drawnow


%% Actions
n_unique_actions = 10;
rng(1)
tx7.String = horzcat('clustering torques to into ', num2str(n_unique_actions), ' unique actions...');
drawnow
actions = kmeans(torque_data, n_unique_actions);
n_unique_actions = length(unique(actions));
disp(horzcat('n unique actions: ', num2str(n_unique_actions)))
disp(horzcat('mode action: ', num2str(mode(actions))))
disp(horzcat('mode action torque: ',  num2str(round(mean(torque_data(mode(actions), :), 1)))))
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
disp('Tuples assembled successfully')


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

