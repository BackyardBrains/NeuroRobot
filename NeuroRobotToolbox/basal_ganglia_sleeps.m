
close all
clear
clc

%% States
nsensors = 2;
raw_or_bag = 2; % 1 = raw, 2 = bag
if raw_or_bag == 1
    nfeatures = 4;
    statemax = 50; % vis_pref_vals = 50, bag = 1        
elseif raw_or_bag == 2
    nfeatures = 5;
    statemax = 1; % vis_pref_vals = 50, bag = 1
end
state_combs = combinator(2, nsensors * nfeatures,'p','r') - 1;
state_combs = padarray(state_combs, [0 1], 0, 'pre');
state_combs = padarray(state_combs, [0 1], statemax, 'post');
nstates = size(state_combs, 1);
disp(horzcat('nstates: ', num2str(nstates)))

%% Motors
nmotors = 2;
ntorques = 5; % Should be odd number
motor_combs = combinator(ntorques, nmotors,'p','r') - ((0.5 * ntorques) + 0.5);
motor_combs = padarray(motor_combs, [0 1], -floor(ntorques/2), 'pre');
motor_combs = padarray(motor_combs, [0 1], floor(ntorques/2), 'post');
nactions = size(motor_combs, 1);
disp(horzcat('nstates: ', num2str(nactions)))

%% Markov
mdp = createMDP(nstates, nactions);
transition_counter = zeros(size(mdp.T));
reward_counter = zeros(size(mdp.R));

%% Get tuples
tuples = dir('.\Transfer\*tuple.mat');
ntuples = size(tuples, 1);
disp(horzcat('ntuples: ', num2str(ntuples)))
rl_data = zeros(ntuples, 4);
state_data = zeros(ntuples, nsensors * nfeatures);
motor_data = zeros(ntuples, 2);
counter = 0;
rand_tuples = randsample(ntuples, round(ntuples/1.5)); % this will need to be prioritized
for ntuple = rand_tuples' % this will need to be prioritized

    counter = counter + 1;

    if ~rem(ntuple, 100)
        disp(num2str(counter/length(rand_tuples)))
    end

    % Load data
    load(horzcat('.\Transfer\', tuples(ntuple).name))

    if length(rl_tuple{1}) == 10

        % Get state
        state_vector = rl_tuple{1};
        state_data(ntuple, :) = state_vector;
        state_vector = padarray(state_vector, [0 1], 0, 'pre');
        state_vector = padarray(state_vector, [0 1], statemax, 'post');  % Change lone 1 to 50 to do vis_pref_vals  
        r = corr(state_vector', state_combs');
        [~, ind] = max(r);
        rl_state = ind;
    
        % Get action    
        motor_vector = rl_tuple{2};
        motor_vector(motor_vector > 250) = 250;
        motor_vector(motor_vector < -250) = -250;
        motor_data(ntuple, :) = motor_vector;
    
        motor_vector = padarray(motor_vector, [0 1], -250, 'pre');
        motor_vector = padarray(motor_vector, [0 1], 250, 'post');
        r = corr(motor_vector', motor_combs');
        [~, ind] = max(r);
        rl_action = ind;
    
        % Get reward
        rl_reward = rl_tuple{3};
    
        % Get next state
        state_vector = rl_tuple{4};
        state_data(ntuple, :) = state_vector;
        state_vector = padarray(state_vector, [0 1], 0, 'pre');
        state_vector = padarray(state_vector, [0 1], statemax, 'post');  % Change lone 1 to 50 to do vis_pref_vals
        r = corr(state_vector', state_combs');
        [~, ind] = max(r);
        rl_next_state = ind;
    
        % Update MDP
        transition_counter(rl_state, rl_next_state, rl_action) = transition_counter(rl_state, rl_next_state, rl_action) + 1;
        reward_counter(rl_state, rl_next_state, rl_action) = reward_counter(rl_state, rl_next_state, rl_action) + rl_reward;
    
        % Store data
        rl_data(ntuple, 1) = rl_state;
        rl_data(ntuple, 2) = rl_action;
        rl_data(ntuple, 3) = rl_reward;
        rl_data(ntuple, 4) = rl_next_state;

%         disp(num2str(rl_state))
    
    end

end

%%
figure(1)
clf

subplot(3,1,1)
histogram(rl_data(:,1), 'binwidth', 10)
hold on
histogram(rl_data(rl_data(:,3) > 0,1), 'binwidth', 10)
set(gca, 'yscale', 'log')
title('States and Rewarded States')
xlabel('State')
ylabel('Count')

subplot(3,1,2)
histogram(rl_data(:,2), 'binwidth', 1)
hold on
histogram(rl_data(rl_data(:,3) > 0,2), 'binwidth', 1)
set(gca, 'yscale', 'log')
title('Actions and Rewarded Actions')
xlabel('Action')
ylabel('Count')

subplot(3,1,3)
% plot(sum(mean(transition_counter, 3)))
% hold on
test = reward_counter ./ transition_counter;
test(isnan(test)) = 0;
plot(sum(mean(test, 3)))
axis tight
title('Transitions and Rewards')
ylabel('Count')
xlabel('State')

transition_counter_save = transition_counter;
reward_counter_save = reward_counter;

%% Build Markov process
transition_counter = transition_counter_save;
for ii_state = 1:nstates
    for naction = 1:nactions
        this_sum = sum(transition_counter(ii_state, :, naction));
        if this_sum
            transition_counter(ii_state, :, naction) = transition_counter(ii_state, :, naction) / this_sum;
        else
            transition_counter(ii_state, :, naction) = 1/nstates;
        end
    end
end

%% 
mdp.T = transition_counter;
reward_counter = reward_counter_save ./ transition_counter_save;
reward_counter(isnan(reward_counter)) = 0;
mdp.R = reward_counter;
env = rlMDPEnv(mdp);
env.ResetFcn = @() ((0.5 * nactions) + 0.5);
validateEnvironment(env)

obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
qTable = rlTable(obsInfo, actInfo);

critic = rlQValueFunction(qTable,obsInfo,actInfo); % Learn rate

%%
agent_opt = rlDQNAgentOptions;
agent_opt.DiscountFactor = 0.01;
agent_opt.EpsilonGreedyExploration.Epsilon = 0.01;
agent_opt.EpsilonGreedyExploration.EpsilonMin = 0.001;
agent_opt.EpsilonGreedyExploration.EpsilonDecay = 0.0005;
agent = rlDQNAgent(critic, agent_opt);

training_opts = rlTrainingOptions;
training_opts.MaxStepsPerEpisode = 100;
training_opts.MaxEpisodes = 10000;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 10;
training_opts.UseParallel = true;
trainingStats = train(agent,env, training_opts);

save('agent_10-11_Steps_50', 'agent')

%% Test controller

% this_action = getAction(agent, 1)

this_state = randsample(nstates, 1)
this_action = getAction(agent, this_state)


%%
%% Train
% agent_opts = rlQAgentOptions;
% agent_opts.DiscountFactor = 0.95;
% agent_opts.EpsilonGreedyExploration.Epsilon = 0.9;
% agent_opts.EpsilonGreedyExploration.EpsilonDecay = 0.01;
% agent_opts.CriticOptimizerOptions = critic_opts;
% agent = rlQAgent(critic,agent_opts);
% opt = rlSARSAAgentOptions;
% agent = rlSARSAAgent(critic,opt);
% training_opts = rlTrainingOptions;
% training_opts.MaxStepsPerEpisode = 50;
% training_opts.MaxEpisodes = 500;
% training_opts.StopTrainingCriteria = "AverageReward";
% training_opts.ScoreAveragingWindowLength = 5;
% % % training_opts.UseParallel = true;
% trainingStats = train(agent,env);
% action = getAction(agent, 13)
% sim_data = sim(agent,env);
% cumulativeReward = sum(sim_data.Reward)
% QTable = getLearnableParameters(getCritic(agent));
% QTable{1}
% mdp.TerminalStates = ["s2";"s14"];




%% Get distances
dists = pdist(state_data);
links = linkage(dists, 'average');
figure(11)
clf
[~, ~, o] = dendrogram(links, size(state_data, 1));

% %% Clustering
% ngroups = 100;
% clusts = cluster(links,'maxclust',ngroups);
% for ii = 1:ngroups
%     figure(ii) 
%     clf
%     montage({frames{clusts == ii}})
%     title(horzcat('Group ', num2str(ii)))
% end
% figure(ii+1)
% histogram(clusts, 'binwidth', 1)
