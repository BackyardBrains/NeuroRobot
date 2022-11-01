
%% Basal ganglia

clear
clc

reward_states = 2:6; % livingroom_net watching tv
localdata_dir_name = 'C:\Users\Christopher Harris\Dataset 1\';
shared_data_dir_name = '.\RL\';
rec_dir_name = 'PreTraining\';

% image_dir = dir(fullfile(strcat(localdata_dir_name, rec_dir_name), '**\*.png'));
% save(strcat(shared_data_dir_name, 'image_dir'), 'image_dir')
load(strcat(shared_data_dir_name, 'image_dir'))

% serial_dir = dir(fullfile(strcat(localdata_dir_name, rec_dir_name), '**\*serial_data.mat'));
% save(strcat(shared_data_dir_name, 'serial_dir'), 'serial_dir')
% load(strcat(shared_data_dir_name, 'serial_dir'))

% torque_dir = dir(fullfile(strcat(localdata_dir_name, rec_dir_name), '**\*torques.mat'));
% save(strcat(shared_data_dir_name, 'torque_dir'), 'torque_dir')
load(strcat(shared_data_dir_name, 'torque_dir'))

ntorques = size(torque_dir, 1);
ntuples = size(torque_dir, 1);
disp(horzcat('ntuples: ', num2str(ntuples)))


%% Dists
% get_dists
% save(strcat(shared_data_dir_name, 'dists'), 'dists')
% load(strcat(shared_data_dir_name, 'dists'))
% dists = dists(:,1);
% dists = dists/max(dists);
% dists = round(dists * (n_unique_states - 1));
% states = dists + 1;


%% States
n_unique_states = 179;
get_states2

ntuples = size(states, 1);
disp(horzcat('ntuples: ', num2str(ntuples)))
disp(horzcat('n unique states: ', num2str(n_unique_states)))
clear labels
for nstate = 1:n_unique_states
    labels{nstate} = num2str(nstate);
end

%% Torques
% get_torques
% save(strcat(shared_data_dir_name, 'torque_data'), 'torque_data')
load(strcat(shared_data_dir_name, 'torque_data'))

%% Actions
n_unique_actions = 9;
actions = kmeans(torque_data, n_unique_actions);
still = torque_data(:,1) == 0 & torque_data(:,2) == 0;
disp(horzcat('n still actions: ', num2str(sum(still))))
actions(still) = n_unique_actions + 1;
save(strcat(shared_data_dir_name, 'actions'), 'actions')

load(strcat(shared_data_dir_name, 'actions'))
figure(7)
gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*0.75, torque_data(:,2)+randn(size(torque_data(:,2)))*0.75, actions)
n_unique_actions = length(unique(actions));
disp(horzcat('n unique actions: ', num2str(n_unique_actions)))


%% Get tuples
tuples = zeros(ntuples - 6, 3);
for nstate = 6:ntuples - 1
    tuples(nstate - 5, 1) = states(nstate - 5);
    tuples(nstate - 5, 2) = states(nstate);
    tuples(nstate - 5, 3) = actions(nstate - 5);
end
ntuples = size(tuples, 1);


%% Lucid sleep?
% basal_ganglia_lucid


%% Get Markov Decision Process
mdp = createMDP(n_unique_states, n_unique_actions);
transition_counter = zeros(size(mdp.T));
for nstate = 1:ntuples

    this_state = tuples(nstate, 1);
    this_next_state = tuples(nstate, 2);
    this_action = tuples(nstate, 3);
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
        if naction == 1
            transition_counter(ii_state, :, naction) = 0;
            transition_counter(ii_state, ii_state, naction) = 1;
        else
            transition_counter(ii_state, :, naction) = this_val;
        end
    end
end

mdp.T = transition_counter;
save(strcat(shared_data_dir_name, 'mdp'), 'mdp')
load(strcat(shared_data_dir_name, 'mdp'))
disp('Markov ready')

%% Get rewards
disp('Getting reward...')
rcount = 0;
rewards = zeros(ntuples, 1) - 1;
for nstate = 1:ntuples
    if ~rem(nstate, round(ntuples/5))
        disp(num2str(nstate/ntuples))
    end
    if sum(tuples(nstate, 1) == reward_states) && sum(tuples(nstate, 3) == mode(actions))
        rewards(nstate) = 1;
        rcount = rcount + 1;
    end
end
disp(horzcat('Total reward count: ', num2str(sum(rcount))))
disp(horzcat('Rewards per step: ', num2str(sum(rewards)/ntuples)))

reward_counter = zeros(size(mdp.R)) - 1;
reward_counter(:,reward_states, mode(actions)) = 1;
mdp.R = reward_counter;
disp(horzcat('total reward: ', num2str(sum(reward_counter(:)))))
save(strcat(shared_data_dir_name, 'rmdp'), 'mdp')
load(strcat(shared_data_dir_name, 'rmdp'))
disp('Rewards ready')


%% Plot mdp
figure(8)
clf
set(gcf, 'position', [100 50 1280 720], 'color', 'w')

subplot(2,2,1)
histogram(tuples(:,1), 'binwidth', .25)
title('States')
xlabel('State')
ylabel('States')

subplot(2,2,2)
histogram(tuples(:,3), 'binwidth', .25)
title('Actions')
xlabel('Action')
ylabel('Actions')

subplot(2,2,4)
plot(rewards)
axis tight
title('Rewards')
xlabel('Time (steps)')
ylabel('Reward value')

subplot(2,2,3)
imagesc(mean(transition_counter, 3), [0 0.3])
colorbar
title('Transition probabilities (avg across actions)')
ylabel('State')
xlabel('Next State')
export_fig(horzcat(shared_data_dir_name, 'mdp_', num2str(date)), '-r150', '-jpg', '-nocrop')


%% Train agents
env = rlMDPEnv(mdp);
save(strcat(shared_data_dir_name, 'env'), 'env')
load(strcat(shared_data_dir_name, 'env'))

validateEnvironment(env)
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
qTable = rlTable(obsInfo, actInfo);
critic = rlQValueFunction(qTable,obsInfo,actInfo);

n_unique_states = size(obsInfo.Elements, 1);
n_unique_actions = size(actInfo.Elements, 1);
disp('Environment ready')


%% Agent 1 (Q)
agent_opt = rlQAgentOptions;
qOptions = rlOptimizerOptions;
% qOptions.LearnRate = 0.1;
agentOpts.CriticOptimizerOptions = qOptions;
agent = rlQAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 500;
training_opts.MaxStepsPerEpisode = 500;
training_opts.StopTrainingValue = 500;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 50;
trainingStats_shallow = train(agent,env, training_opts);


%%
figure(11)
scan_agent
title(horzcat('AgentTV'))
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat(shared_data_dir_name, 'AgentTV'), '-r150', '-jpg', '-nocrop')
save(horzcat(shared_data_dir_name, 'AgentTV'), 'agent')


%% Agent 2 (Deep Q)
agent_opt = rlDQNAgentOptions;
agent = rlDQNAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 500;
training_opts.MaxStepsPerEpisode = 500;
training_opts.StopTrainingValue = 500;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 50;
training_opts.UseParallel = 0;
trainingStats_deep = train(agent, env, training_opts);

%%
figure(12)
scan_agent
title('DeepAgentTV')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat(shared_data_dir_name, 'DeepAgentTV'), '-r150', '-jpg', '-nocrop')
save(horzcat(shared_data_dir_name, 'DeepAgentTV'), 'agent')


