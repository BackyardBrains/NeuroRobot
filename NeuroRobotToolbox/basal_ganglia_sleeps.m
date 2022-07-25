
clear
clc

rand_states = 0;

%% Ontology
classifier_dir_name = '.\Data_1\Rec_2\';
labels = folders2labels(classifier_dir_name);
unique_states = unique(labels);
n_unique_states = length(unique_states);

%% Tuples
tuples_dir_name = 'C:\Users\Christopher Harris\RandomWalkData\';
image_dir = dir(fullfile(tuples_dir_name, '**\*.png'));
% serial_dir = dir(fullfile(tuples_dir_name, '**\*serial_data.mat'));
torque_dir = dir(fullfile(tuples_dir_name, '**\*torques.mat'));
ntuples = size(torque_dir, 1);

%% States
load livingroom_net
if ~rand_states
    get_states
    save('states2', 'states')
    load('states')
else
    states = ceil(rand(ntuples, 1)*24);
end
states = modefilt(states, [5 1]);

%% Torques
% get_torques
% save('torque_data', 'torque_data')
load('torque_data')

%% Actions
% n_unique_actions = 10;
% actions = kmeans(torque_data, n_unique_actions);
% save('actions', 'actions')
load('actions')
n_unique_actions = length(unique(actions));
figure; gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*2, torque_data(:,2)+randn(size(torque_data(:,2)))*2, actions)

%% Distances
% get_dists
% save('dists', 'dists')
load('dists')

%% Checksum
disp(horzcat('n unique states: ', num2str(n_unique_states)))
disp(horzcat('n uniqe actions: ', num2str(n_unique_actions)))
disp(horzcat('n tuples: ', num2str(ntuples)))

%% Get tuples
atuples = zeros(ntuples - 5, 3);
btuples = [];
moving = 0;
moving_counter = [];
tlog = [];
for ntuple = 5:ntuples - 1
    if ~rem(ntuple, round((ntuples-1)/10))
        disp(num2str(ntuple/(ntuples-1)))
    end
    this_state = states(ntuple);
    atuples(ntuple - 4, 1) = this_state;
    atuples(ntuple - 4, 2) = states(ntuple + 1);
    atuples(ntuple - 4, 3) = actions(ntuple - 4);
end


%% Get Markov Decision Process
tuples = atuples;
ntuples = size(tuples, 1);

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

%% Get reward
reward_counter = zeros(size(mdp.R));
reward_counter(:,[1:4 13:16], 1) = 1;
reward_counter(:,[9:12 21:24], 1) = -1;
mdp.R = reward_counter;
disp(horzcat('total reward: ', num2str(sum(reward_counter(:)))))
if rand_states
    save('rmdp', 'mdp')
else
    save('mdp', 'mdp')
end


%% Plot mdp
figure(10)
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

subplot(2,2,3)
imagesc(mean(transition_counter, 3), [0 0.15])
colorbar
title('Transitions')

subplot(2,2,4)
imagesc(mean(reward_counter, 3))
colorbar
title('Reward')

if rand_states
    export_fig(horzcat('rmdp_', num2str(date)), '-r150', '-jpg', '-nocrop')
else
    export_fig(horzcat('mdp_', num2str(date)), '-r150', '-jpg', '-nocrop')
end

%% Train agents
filename = 'mdp';
load(filename)
env = rlMDPEnv(mdp);

validateEnvironment(env)
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
qTable = rlTable(obsInfo, actInfo);
critic = rlQValueFunction(qTable,obsInfo,actInfo);

n_unique_states = size(obsInfo.Elements, 1);
n_unique_actions = size(actInfo.Elements, 1);


%% Agent 1 (Q)
agent_opt = rlQAgentOptions;
qOptions = rlOptimizerOptions;
% qOptions.LearnRate = 0.1;
agentOpts.CriticOptimizerOptions = qOptions;
agent = rlQAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 2000;
training_opts.MaxStepsPerEpisode = 10;
training_opts.StopTrainingValue = 10000;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 100;
trainingStats_shallow = train(agent,env, training_opts);
figure(11)
clf
set(gcf, 'color', 'w')
scan_agent
ylim([0 n_unique_states + 1])
title(horzcat('Agent 1 - ', filename))
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat('agent1_', filename, '_net'), '-r150', '-jpg', '-nocrop')
save(horzcat('agent1_', filename), 'agent')


%% Agent 2 (Deep Q)
agent_opt = rlDQNAgentOptions;
agent = rlDQNAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 2000;
training_opts.MaxStepsPerEpisode = 10;
training_opts.StopTrainingValue = 10000;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 100;
training_opts.UseParallel = 1;
trainingStats_deep = train(agent, env, training_opts);
figure(12)
clf
set(gcf, 'color', 'w')
scan_agent
ylim([0 n_unique_states + 1])
title(horzcat('Agent 2 - ', filename))
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat('agent2_', filename, '_net'), '-r150', '-jpg', '-nocrop')
save(horzcat('agent2_', filename), 'agent')


