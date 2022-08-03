
%% Basal ganglia

clear
clc

reward_states = [7 22 35 37];
rand_states = 0;


%% Ontology
classifier_dir_name = '.\Data_1\Rec_4\';
labels = folders2labels(classifier_dir_name);
unique_states = unique(labels);
unique_states(unique_states == classifier_dir_name(end-5:end-1)) = [];
n_unique_states = length(unique_states);


%% Tuples
tuples_dir_name = 'C:\Users\Christopher Harris\RandomWalkData\';
image_dir = dir(fullfile(tuples_dir_name, '**\*.png'));
torque_dir = dir(fullfile(tuples_dir_name, '**\*torques.mat'));
ntuples = size(torque_dir, 1);


%% States
load(strcat(classifier_dir_name, 'livingroom_k', num2str(n_unique_states), '_net'))
if ~rand_states
    get_states
    save(strcat(classifier_dir_name, 'states'), 'states')
else
    states = ceil(rand(ntuples, 1)*n_unique_states);
end
% states = modefilt(states, [5 1]);
% load(strcat(classifier_dir_name, 'states'))


%% Torques
get_torques
save(strcat(classifier_dir_name, 'torque_data'), 'torque_data')
% load(strcat(classifier_dir_name, 'torque_data'))


%% Actions
n_unique_actions = 10;
actions = kmeans(torque_data, n_unique_actions);
save(strcat(classifier_dir_name, 'actions'), 'actions')
% load(strcat(classifier_dir_name, 'actions'))
n_unique_actions = length(unique(actions));
% figure(4)
% gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*2, torque_data(:,2)+randn(size(torque_data(:,2)))*2, actions)


%% Get tuples
tuples = zeros(ntuples - 5, 3);
for ntuple = 5:ntuples - 1
    if ~rem(ntuple, round((ntuples-1)/10))
        disp(num2str(ntuple/(ntuples - 6)))
    end
    this_state = states(ntuple);
    tuples(ntuple - 4, 1) = this_state;
    tuples(ntuple - 4, 2) = states(ntuple + 1);
    tuples(ntuple - 4, 3) = actions(ntuple - 4);
end
ntuples = size(tuples, 1);


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


%% Get rewards
rewards = zeros(ntuples, 1) - 1;
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end
    if sum(tuples(ntuple, 1) == reward_states) && sum(tuples(ntuple, 3) == mode(actions))
        rewards(ntuple) = 1;
    end
end
disp(horzcat('Total reward: ', num2str(sum(rewards))))
disp(horzcat('Rewards per step: ', num2str(sum(rewards)/ntuples)))

reward_counter = zeros(size(mdp.R)) - 1;
reward_counter(:,reward_states, 1) = 1;
mdp.R = reward_counter;
disp(horzcat('total reward: ', num2str(sum(reward_counter(:)))))


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
plot(rewards)
title('Rewards')
xlabel('Time (steps)')
ylabel('Reward value')

if rand_states
    export_fig(horzcat(classifier_dir_name, 'rmdp_', num2str(date)), '-r150', '-jpg', '-nocrop')
else
    export_fig(horzcat(classifier_dir_name, 'mdp_', num2str(date)), '-r150', '-jpg', '-nocrop')
end


%% Train agents
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
training_opts.MaxEpisodes = 500;
training_opts.MaxStepsPerEpisode = 100;
training_opts.StopTrainingValue = 1000;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 100;
trainingStats_shallow = train(agent,env, training_opts);
figure(11)
clf
set(gcf, 'color', 'w')
scan_agent
ylim([0 n_unique_states + 1])
title(horzcat('Agent 1'))
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat(classifier_dir_name, 'agent1'), '-r150', '-jpg', '-nocrop')
save(horzcat(classifier_dir_name, 'agent1'), 'agent')


%% Agent 2 (Deep Q)
agent_opt = rlDQNAgentOptions;
agent = rlDQNAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 500;
training_opts.MaxStepsPerEpisode = 100;
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
title('Agent 2')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat(classifier_dir_name, 'agent2'), '-r150', '-jpg', '-nocrop')
save(horzcat(classifier_dir_name, 'agent2'), 'agent')


