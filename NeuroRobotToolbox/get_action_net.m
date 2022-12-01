
%% Get action net

clear
clc

reward_states = 13;
data_dir_name = '.\Datasets\';
rec_dir_name = 'Recordings\PreTraining\';
net_dir_name = '.\Nets\';

load(horzcat(net_dir_name, 'LivingRoomNet'))
load(horzcat(net_dir_name, 'LivingRoomLabels'))

image_dir = dir(fullfile(strcat(data_dir_name, rec_dir_name), '**\*.png'));
torque_dir = dir(fullfile(strcat(data_dir_name, rec_dir_name), '**\*torques.mat'));
save(strcat(data_dir_name, 'image_dir'), 'image_dir')
load(strcat(data_dir_name, 'image_dir'))
save(strcat(data_dir_name, 'torque_dir'), 'torque_dir')
load(strcat(data_dir_name, 'torque_dir'))

ntorques = size(torque_dir, 1);
ntuples = size(torque_dir, 1);
disp(horzcat('ntuples: ', num2str(ntuples)))
unique_states = unique(labels);
n_unique_states = length(unique_states);
disp(horzcat('n unique states: ', num2str(n_unique_states)))


%% States
get_states
save(strcat(net_dir_name, 'states'), 'states')
save('states', 'states')
load(strcat(net_dir_name, 'states'))
ntuples = size(states, 1);
disp(horzcat('ntuples: ', num2str(ntuples)))


%% Torques
get_torques
save(strcat(net_dir_name, 'torque_data'), 'torque_data')
load(strcat(net_dir_name, 'torque_data'))


%% Actions
n_unique_actions = 19;
actions = kmeans(torque_data, n_unique_actions);
still = torque_data(:,1) == 0 & torque_data(:,2) == 0;
disp(horzcat('n still actions: ', num2str(sum(still))))
actions(still) = n_unique_actions + 1;
save(strcat(net_dir_name, 'actions'), 'actions')
load(strcat(net_dir_name, 'actions'))
figure(7)
gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*1.5, torque_data(:,2)+randn(size(torque_data(:,2)))*1.5, actions)
n_unique_actions = length(unique(actions));
disp(horzcat('n unique actions: ', num2str(n_unique_actions)))


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


%% Get Markov Decision Process
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
        if naction == 1
            transition_counter(ii_state, :, naction) = 0;
            transition_counter(ii_state, ii_state, naction) = 1;
        else
            transition_counter(ii_state, :, naction) = this_val;
        end
    end
end

mdp.T = transition_counter;
save(strcat(net_dir_name, 'mdp'), 'mdp')
load(strcat(net_dir_name, 'mdp'))
disp('Markov ready')

%% Get rewards
disp('Getting reward...')
rcount = 0;
rewards = zeros(ntuples, 1) - 1;
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/5))
        disp(num2str(ntuple/ntuples))
    end
    if sum(tuples(ntuple, 1) == reward_states) && sum(tuples(ntuple, 3) == mode(actions))
        rewards(ntuple) = 1;
        rcount = rcount + 1;
    end
end
disp(horzcat('Total reward count: ', num2str(sum(rcount))))
disp(horzcat('Rewards per step: ', num2str(sum(rewards)/ntuples)))

reward_counter = zeros(size(mdp.R)) - 1;
reward_counter(:,reward_states, mode(actions)) = 1;
mdp.R = reward_counter;
disp(horzcat('total reward: ', num2str(sum(reward_counter(:)))))
save(strcat(net_dir_name, 'rmdp'), 'mdp')
load(strcat(net_dir_name, 'rmdp'))
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
export_fig(horzcat(net_dir_name, 'mdp_', num2str(date)), '-r150', '-jpg', '-nocrop')


%% Train agents
env = rlMDPEnv(mdp);
save(strcat(net_dir_name, 'env'), 'env')
load(strcat(net_dir_name, 'env'))

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
qOptions.LearnRate = 1;
agentOpts.CriticOptimizerOptions = qOptions;
agent = rlQAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 1000;
training_opts.MaxStepsPerEpisode = 500;
training_opts.StopTrainingValue = 500;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 10;
trainingStats_shallow = train(agent,env, training_opts);


%%
figure(11)
scan_agent
title(horzcat('LivingRoomAgent'))
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat(net_dir_name, 'LivingRoomAgent'), '-r150', '-jpg', '-nocrop')
save(horzcat(net_dir_name, 'LivingRoomAgent'), 'agent')


%% Agent 2 (Deep Q)
agent_opt = rlDQNAgentOptions;
agent = rlDQNAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 500;
training_opts.MaxStepsPerEpisode = 100;
training_opts.StopTrainingValue = 500;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 50;
training_opts.UseParallel = 0;
trainingStats_deep = train(agent, env, training_opts);

%%
figure(12)
scan_agent
title('DeepLivingRoomAgent')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat(net_dir_name, 'DeepLivingRoomAgent'), '-r150', '-jpg', '-nocrop')
save(horzcat(net_dir_name, 'DeepLivingRoomAgent'), 'agent')


