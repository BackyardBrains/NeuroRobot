
%% Get directory
if olearn_data_select.Value > 1
    rec_dir_name = available_datasets{olearn_data_select.Value};
else
    rec_dir_name = '';
end


%% Get net
net_name = training_nets{olearn_net_load_select.Value};


%%
axes(olearn_data_status_ax)

cla
tx7 = text(0.03, 0.5, horzcat('loading net...'));
drawnow
disp('Loading state net...')

load(strcat(nets_dir_name, net_name, '-ml'))
load(strcat(nets_dir_name, net_name(1:end-4), '-labels'))

n_unique_states = length(labels);
disp(horzcat('n unique states: ', num2str(n_unique_states)))

tx7.String = 'indexing data..';
drawnow
disp('indexing data...')

image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*.png'));
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
n_unique_actions = 9;
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


%% Get Markov Decision Process
axes(olearn_data_status_ax)
cla
tx8 = text(0.03, 0.5, horzcat('creating world model (MDP)...'));
drawnow

mdp = createMDP(n_unique_states, n_unique_actions);
transition_counter = zeros(size(mdp.T));
for ntuple = 1:ntuples

    this_state = tuples(ntuple, 1);
    this_next_state = tuples(ntuple, 2);
    this_action = tuples(ntuple, 3);
    if ~isnan(this_state) && ~isnan(this_next_state)
        if this_state && this_next_state
            transition_counter(this_state, this_next_state, this_action) = transition_counter(this_state, this_next_state, this_action) + 1;
        end
    end
end

disp(horzcat('n transitions: ', num2str(sum(transition_counter(:)))))
transition_counter_save = transition_counter;

for ii_state = 1:n_unique_states
    for naction = 1:n_unique_actions
        this_sum = sum(transition_counter(ii_state, :, naction));
        if this_sum
            this_val = transition_counter(ii_state, :, naction) / this_sum;
        else
            this_val = zeros(size(transition_counter(ii_state, :, naction)));
            flag = 0;
            disp('padding mdp')
            while ~flag
                if sum(this_val) < 1
                    this_state = randsample(n_unique_states, 1);
                    this_val(this_state) = this_val(this_state) + 0.001;
                else
                    flag = 1;
                end
            end
        end

        if naction == mode(actions)
            transition_counter(ii_state, :, naction) = 0;
            transition_counter(ii_state, ii_state, naction) = 1;
        else
            transition_counter(ii_state, :, naction) = this_val;
        end
%         transition_counter(ii_state, :, naction) = this_val;
    end
end

mdp.T = transition_counter;
save(strcat(nets_dir_name, net_name, '-mdp'), 'mdp')
disp('Markov ready')


%% Output
tx8.String = 'Markov ready';
drawnow

axes(im_ax1)
cla
imagesc(mean(transition_counter, 3), [0 1])
title('Transition probabilities (avg across actions)')
ylabel('State')
xlabel('Next State')

ml_visualize_mdp
