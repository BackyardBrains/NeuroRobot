
close all
clear

% States
nsensors = 2;
nfeatures = 5;
all_combs = combinator(2, nsensors * nfeatures,'p','r') - 1;
nstates = size(all_combs, 1);

% Motors
nmotors = 2;
ntorques = 10;
nactions = ntorques^nmotors;

% Markov
mdp = createMDP(nstates, nactions);
transition_counter = zeros(size(mdp.T));
reward_counter = zeros(size(mdp.R));

% Get tuples
tuples = dir('.\Experiences\*tuple.mat');
ntuples = size(tuples, 1);
data = zeros(ntuples, 4);
motor_data = zeros(ntuples, 2);

for ntuple = 2:ntuples % this will need to be randomized then prioritized

    disp(horzcat('ntuple: ', num2str(ntuple)))
    
    % Load data
    load(horzcat('.\Experiences\', tuples(ntuple).name))

    % Get state
    state_vector = rl_tuple{1};
    r = corr(state_vector', all_combs');
    [~, ind] = max(r);
    rl_state = ind;

    % Get action    
    torques = rl_tuple{2};
    torques = round(5 * ((torques / 250) + 1)); % convert from 2 continuous vals to 100 combs
    rl_action = (torques(1)*10 + torques(2)) + 1;
    rl_action(rl_action > nactions) = nactions;
    motor_data(ntuple, :) = rl_tuple{2};

    % Get reward
    rl_reward = rl_tuple{3};

    % Get next state
    state_vector = rl_tuple{4};
    r = corr(state_vector', all_combs');
    [~, ind] = max(r);
    rl_next_state = ind;

    % Update MDP
    transition_counter(rl_state, rl_next_state, rl_action) = transition_counter(rl_state, rl_next_state, rl_action) + 1;
    reward_counter(rl_state, rl_next_state, rl_action) = reward_counter(rl_state, rl_next_state, rl_action) + rl_reward;

    % Store data
    data(ntuple, 1) = rl_state;
    data(ntuple, 2) = rl_action;
    data(ntuple, 3) = rl_reward;
    data(ntuple, 4) = rl_next_state;

end
    

%%
figure(1)
clf
subplot(3,1,1)
histogram(data(:,1), 'binwidth', 1)
title('States')
subplot(3,1,2)
histogram(data(:,2), 'binwidth', 1)
title('Actions')
subplot(3,1,3)
histogram(data(data(:,3) > 0,4), 'binwidth', 1)
title('Rewarded states')

%%
transition_matrix = ones(size(mdp.T));
transition_matrix = transition_matrix ./ sum(transition_matrix(:,2));
mdp.T = transition_matrix;
reward_counter = reward_counter ./ sum(reward_counter(:,2));
reward_counter(isnan(reward_counter)) = 0;
mdp.R = reward_counter;
env = rlMDPEnv(mdp);
env.ResetFcn = @() 1;

%% Train
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
qTable = rlTable(obsInfo, actInfo);
critic = rlQValueRepresentation(qTable,obsInfo,actInfo);
critic_opts = rlOptimizerOptions;
critic_opts.LearnRate = 1;

agent_opts = rlQAgentOptions;
agent_opts.DiscountFactor = 0.2;
agent_opts.EpsilonGreedyExploration.Epsilon = 0.9;
agent_opts.EpsilonGreedyExploration.EpsilonDecay = 0.01;
agent_opts.CriticOptimizerOptions = critic_opts;
agent = rlQAgent(critic,agent_opts);

training_opts = rlTrainingOptions;
training_opts.MaxStepsPerEpisode = 20;
training_opts.MaxEpisodes = 500;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 5;

trainingStats = train(agent,env,training_opts);

% action = getAction(agent, [0 0 0 0 0 0 0 0 0 0])

% Data = sim(agent,env);
% cumulativeReward = sum(Data.Reward)
% QTable = getLearnableParameters(getCritic(agent));
% QTable{1}

% % % % mdp.TerminalStates = ["s2";"s14"];

% % % 
% % % %% Get agent
% % % obsInfo = rlFiniteSetSpec(1:nstates); % binary thresholded bag-of-features histogram (1000 states total)
% % % actInfo = rlFiniteSetSpec(1:nactions); % 50-levels thresholded motor (2) speaker (5) and lights (3) (500 states total)
% % % 
% % % qTable = rlTable(obsInfo,actInfo);
critic = rlQValueRepresentation(qTable,obsInfo,actInfo);
% % % 
% % % opt = rlQAgentOptions;
% % % agent = rlQAgent(critic,opt);
% % % 
% % % % opt = rlSARSAAgentOptions;
% % % % agent = rlSARSAAgent(critic,opt)
% % % 
% % % %% Train agent
% % % opt = rlTrainingOptions;
% % % trainOpts.MaxStepsPerEpisode = 50;
% % % trainOpts.MaxEpisodes = 500;
% % % trainStats = train(agent,env,opt);
% % % 
% % % %% Test :)
% % % % value = getValue(critic,{5},{9})
% % % % action = getAction(agent,{8})
% % % 
% % % 
% % % 
% % % 
% % %