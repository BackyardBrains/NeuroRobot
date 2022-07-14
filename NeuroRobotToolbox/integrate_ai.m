
clear
clc


draw_steps = 1;

%% Ontology
classifier_dir_name = '.\Data_1\Rec_2\';
labels = folders2labels(classifier_dir_name);
unique_states = unique(labels);
n_unique_states = length(unique_states);

%% Tuples
tuples_dir_name = '.\Data_2\Rec_6\';
image_dir = dir(fullfile(tuples_dir_name, '**\*.png'));
torque_dir = dir(fullfile(tuples_dir_name, '**\*torques.mat'));
serial_dir = dir(fullfile(tuples_dir_name, '**\*serial_data.mat'));
ntuples = size(torque_dir, 1);

%% States
load livingroom2_net
% get_states
load('states')
states = modefilt(states, [5 1]);

%% Torques
% get_torques
load('torque_data')

%% Distances
% get_dists
load('dists')

%% Actions
torque_vals = 2;
motor_combs = combinator(torque_vals, 2,'p','r') - ((0.5 * torque_vals) + 0.5);
motor_combs = motor_combs * 50;
motor_combs = [motor_combs(1:2,:); [0 0]; motor_combs(3:4,:)];
motor_combs = padarray(motor_combs, [0 1], rand * 0.00001, 'pre');
motor_combs = padarray(motor_combs, [0 1], rand * 0.00001, 'post');
n_unique_actions = size(motor_combs, 1);
% get_actions
load('actions')

%% Checksum
disp(horzcat('n unique states: ', num2str(n_unique_states)))
disp(horzcat('n uniqe actions: ', num2str(n_unique_actions)))
disp(horzcat('n tuples: ', num2str(ntuples)))

%% 
state_buffer = [];
next_state_buffer = [];
torque_buffer = [];
action_buffer = [];
dist_buffer = [];
atuples = zeros(ntuples - 1, 3);
btuples = [];
moving = 0;
moving_counter = [];
tlog = [];
for ntuple = 1:ntuples - 1

    if ~rem(ntuple, round((ntuples-1)/10))
        disp(num2str(ntuple/(ntuples-1)))
    end

    this_state = states(ntuple);
    these_torques = torque_data(ntuple, :);

    state_buffer = [state_buffer; this_state];
    torque_buffer = [torque_buffer; these_torques];

    atuples(ntuple, 1) = this_state;
    atuples(ntuple, 2) = states(ntuple + 1);
    atuples(ntuple, 3) = actions(ntuple);    
    
%     if sum(these_torques)
    if this_state ~= states(ntuple + 1)
        moving = moving + 1;
        tlog = [tlog ntuple];
    elseif moving
        moving_counter = [moving_counter moving];
        tlog = [tlog ntuple];

        this_val = size(torque_buffer, 1) - moving - 5;
        this_val = max([this_val, 1]);

        motor_vector = mean(torque_buffer(this_val:end-2, :), 1);
        motor_vector = padarray(motor_vector, [0 1], rand * 0.00001, 'pre');
        motor_vector = padarray(motor_vector, [0 1], rand * 0.00001, 'post');
        r = corr(motor_vector', motor_combs');  
        [~, this_action] = max(r);

        btuples = [btuples; state_buffer(1), state_buffer(end), this_action];

%         clc
%         disp(horzcat('sequence: ', num2str(length(moving_counter))))
%         disp(horzcat('movements: ', num2str(moving)))
%         disp(horzcat('tuples: ', num2str(tlog(1)), ' to ', num2str(tlog(end))))

        state_buffer = [];
        torque_buffer = [];
        tlog = [];
        moving = 0;

    else
        state_buffer = [];
        tlog = [];
%         torque_buffer = [];
    end
end


%% Get Markov Decision Process
% tuples = atuples;
tuples = btuples;
ntuples = size(tuples, 1);

mdp = createMDP(n_unique_states, n_unique_actions);
transition_counter = zeros(size(mdp.T));
for ntuple = 1:ntuples

    this_state = tuples(ntuple, 1);
    this_next_state = tuples(ntuple, 2);
    this_action = tuples(ntuple, 3);
    if this_state && this_next_state
        transition_counter(this_state, this_next_state, this_action) = transition_counter(this_state, this_next_state, this_action) + 1;
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
            while ~flag
                if sum(this_val) < 1
                    sum(this_val)
                    this_state = randsample(n_unique_states, 1);
                    this_val(this_state) = this_val(this_state) + 0.001;
                    disp('padded')
                else
                    flag = 1;
                end
            end
        end
        transition_counter(ii_state, :, naction) = this_val;
    end
end

mdp.T = transition_counter;

%% Plot mdp
figure(1)
clf
set(gcf, 'position', [100 50 1280 720], 'color', 'w')

subplot(2,2,1)
histogram(tuples(:,1), 'binwidth', 1)
title('States')
xlabel('State')
ylabel('States')

subplot(2,2,2)
histogram(tuples(:,3), 'binwidth', .25)
title('Actions')
xlabel('Action')
ylabel('Actions')

subplot(2,2,3)
imagesc(mean(transition_counter, 3), [0 0.2])
colorbar
title('Transitions')

subplot(2,2,4)
histogram(moving_counter)
set(gca, 'yscale', 'log')
title('Movements per sequence')
xlabel('Movements')
ylabel('Sequences')

export_fig(horzcat('mdp_', num2str(date)), '-r150', '-jpg', '-nocrop')

%% Get reward
reward_counter = zeros(size(mdp.R));
reward_counter = reward_counter - 1;
reward_counter(:,[1:4, 13:16],[1:2, 4:5]) = 10;
mdp.R = reward_counter;
disp(horzcat('total reward: ', num2str(sum(reward_counter(:)))))
% mdp.TerminalStates = "s14";

%% Scramble 
save('mdp', 'mdp')
for nstate = 1:n_unique_states
    for naction = 1:n_unique_actions
        this_array = mdp.T(nstate, :, naction);
        mdp.T(nstate, :, naction) = this_array(randperm(length(this_array)));
    end
end
save('rmdp', 'mdp')

figure(1)
subplot(1,2,1)
load('mdp')
imagesc(mean(mdp.T, 3), [0 0.2])
title('MDP')
subplot(1,2,2)
load('rmdp')
imagesc(mean(mdp.T, 3), [0 0.2])
title('RMDP')

