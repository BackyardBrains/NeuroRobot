

%%
axes(ml_train1_status)

cla
tx7 = text(0.03, 0.5, horzcat('loading net...'));
drawnow
disp('Loading state net...')

load(strcat(nets_dir_name, net_name, '-ml'))
load(strcat(nets_dir_name, net_name, '-labels'))

n_unique_states = length(labels);
disp(horzcat('n unique states: ', num2str(n_unique_states)))

tx7.String = 'indexing data..';
drawnow
disp('indexing data...')

image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*_x.png'));
torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));

ntorques = size(torque_dir, 1);
nimages = size(image_dir, 1);
ntuples = ntorques;
disp(horzcat('ntuples: ', num2str(ntuples)))


%% States
tx7.String = 'getting states..';
drawnow
disp('assembling tuples...')

get_states
save(horzcat(nets_dir_name, net_name, '-states'), 'states')


%% Torques
tx7.String = 'loading torques..';
drawnow
get_torques
save(horzcat(nets_dir_name, net_name, '-torque_data'), 'torque_data')
load(horzcat(nets_dir_name, net_name, '-torque_data'))
tx7.String = horzcat('ntorques loaded: ', num2str(ntuples), ' LR torque value pairs, ...');
drawnow


%% Actions
n_unique_actions = 5;
rng(1)
tx7.String = horzcat('clustering torques to into ', num2str(n_unique_actions), ' unique actions...');
drawnow
actions = kmeans(torque_data, n_unique_actions);
n_unique_actions = length(unique(actions));
disp(horzcat('n unique actions: ', num2str(n_unique_actions)))
disp(horzcat('mode action: ', num2str(mode(actions))))
disp(horzcat('mode action torque: ',  num2str(round(mean(torque_data(actions == mode(actions), :), 1)))))
save(strcat(nets_dir_name, net_name, '-actions'), 'actions')
load(strcat(nets_dir_name, net_name, '-actions'))

    motor_combs = zeros(2, n_unique_actions);

    figure(22)
    clf
    gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*4, torque_data(:,2)+randn(size(torque_data(:,2)))*4, actions, [],[],[], 'off')
    hold on
    for naction = 1:n_unique_actions
        motor_combs(naction,:) = mean(torque_data(actions == naction, :));
        text(motor_combs(naction,:), motor_combs(naction,:), num2str(naction), 'fontsize', 16, 'fontweight', 'bold')
    end
    axis padded
    set(gca, 'yscale', 'linear')
    title('Actions')
    xlabel('Torque 1')
    ylabel('Torque 2')
    drawnow


%% Plot torque data with action IDs
axes(im_ax1)
cla
gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*4, torque_data(:,2)+randn(size(torque_data(:,2)))*4, actions, [],[],[], 'off')
hold on
for naction = 1:n_unique_actions
    mean_torque = mean(torque_data(actions == naction, :));
    text(mean_torque(1), mean_torque(2), num2str(naction), 'fontsize', 16, 'fontweight', 'bold')
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

