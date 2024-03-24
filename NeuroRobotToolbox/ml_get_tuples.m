

%%
axes(ml_train1_status)

cla
tx7 = text(0.03, 0.5, horzcat('loading net...'), 'FontSize', bfsize + 4);
drawnow
disp('Loading state net...')

load(strcat(nets_dir_name, state_net_name, '-ml'))
load(strcat(nets_dir_name, state_net_name, '-labels'))

n_unique_states = length(labels);
disp(horzcat('n unique states: ', num2str(n_unique_states)))

tx7.String = 'indexing data..';
drawnow
disp('indexing data...')

image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*large_frame_x.jpg'));
torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torque.txt'));

ntorques = size(torque_dir, 1);
nimages = size(image_dir, 1);
ntuples = ntorques;
disp(horzcat('ntuples: ', num2str(ntuples)))


%% States
tx7.String = 'getting states..';
drawnow
disp('assembling tuples...')

get_states
save(horzcat(nets_dir_name, state_net_name, '-states'), 'states')
load(horzcat(nets_dir_name, state_net_name, '-states'))


%% Torques
tx7.String = 'loading torques..';
drawnow
clear get_torques
get_torques
% torque_data = fliplr(torque_data); % 240309 fix
save(horzcat(nets_dir_name, state_net_name, '-torque_data'), 'torque_data')
load(horzcat(nets_dir_name, state_net_name, '-torque_data'))
tx7.String = horzcat('ntorques loaded: ', num2str(ntuples), ' LR torque value pairs, ...');
drawnow


%% Actions
n_unique_actions = 10; % This needs to be settable
actions = kmeans(torque_data, n_unique_actions);

% h = histogram(actions, 'binwidth', 1);
% h2 = h.Values/sum(h.Values) > 0.01;
% sum(h2)
% n_unique_actions = sum(h2);
% actions = kmeans(torque_data, n_unique_actions);
% h = histogram(actions, 'binwidth', 1);
% h2 = h.Values/sum(h.Values) > 0.01;
% sum(h2)

motor_combs = zeros(n_unique_actions, 2);

counter = 0;
while ~(sum(sum(motor_combs, 2) < 0) == 1) && counter < 5
    counter = counter + 1;
    actions = kmeans(torque_data, n_unique_actions);
    for naction = 1:n_unique_actions
        motor_combs(naction, :) = mean(torque_data(actions == naction, :));
    end
end

% tx7.String = horzcat('clustering torques to into ', num2str(n_unique_actions), ' unique actions...');
drawnow

% figure(11)
% h = histogram(actions);
% drawnow
% ns = h.Values;
% close(11)
% [~, xinds] = sort(ns, 'ascend');
% actions(actions == xinds(1)) = mode(actions);
% actions(actions == xinds(2)) = mode(actions);

% n_unique_actions = length(unique(actions));

disp(horzcat('n unique actions: ', num2str(n_unique_actions)))
disp(horzcat('mode action: ', num2str(mode(actions))))
disp(horzcat('mode action torque: ',  num2str(round(mean(torque_data(actions == mode(actions), :), 1)))))

save(strcat(nets_dir_name, state_net_name, '-actions'), 'actions')
load(strcat(nets_dir_name, state_net_name, '-actions'))

axes(im_ax1)
cla
gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*4, torque_data(:,2)+randn(size(torque_data(:,2)))*4, actions, [],[],[], 'off')
hold on
for naction = 1:n_unique_actions
    text(motor_combs(naction,1), motor_combs(naction,2), num2str(naction), 'fontsize', 16, 'fontweight', 'bold');
end
axis padded
set(gca, 'yscale', 'linear')
title('Actions')
xlabel('Torque 1')
ylabel('Torque 2')
drawnow

figure(9)
clf
gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*4, torque_data(:,2)+randn(size(torque_data(:,2)))*4, actions, [],[],[], 'off')
hold on
for naction = 1:n_unique_actions
    text(motor_combs(naction,1), motor_combs(naction,2), num2str(naction), 'fontsize', 16, 'fontweight', 'bold')
end
axis padded
set(gca, 'yscale', 'linear')
title('Actions')
xlabel('Right motor torque')
ylabel('Left motor torque')
drawnow

%% Get tuples
tuples = zeros(ntuples, 3);
for ntuple = 6:ntuples - 1
    tuples(ntuple - 5, 1) = states(ntuple - 5);
    tuples(ntuple - 5, 2) = states(ntuple);
    tuples(ntuple - 5, 3) = actions(ntuple - 5);
end
ntuples = size(tuples, 1);
disp('Tuples assembled successfully')
save(strcat(nets_dir_name, state_net_name, '-tuples'), 'tuples')
load(strcat(nets_dir_name, state_net_name, '-tuples'))


%% Lucid sleep?
% basal_ganglia_lucid


%% Output
% tx7.String = 'tuples aquired successfully';
drawnow

figure(12)
clf
set(gcf, 'position', [201 241 1200 420], 'color', 'w')

subplot(1,3,1:2)
histogram(states)
title('States')
subplot(1,3,3)
histogram(actions)
title('Actions')


