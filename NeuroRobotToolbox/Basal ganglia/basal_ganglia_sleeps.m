
% This script uses experience replay to create a reinforcement learning
% training environment, it then trains an RL agent in the environment. 
% The trained net can then be used to for automatic adaptive state-action
% mapping in SpikerBots
% First record tuples during behavior by different brains or low_entropy_pattern_generator.m
% but with consistent rewards for e.g. seeing green, responding to sounds, being in a specific part of the room, being fun etc

% https://www.mathworks.com/help/reinforcement-learning/ug/train-reinforcement-learning-agent-in-mdp-environment.html

clc
clear
close all

tic

% nstates = 500*2; % binary-thresholded bag-of-features histogram for one eye frame
% nactions = 10*50; % 50-level-thresholded controller for motors (2) speaker (5) and lights (3)
nstates = 2*24; % vis_prev_vals(:) * binary threshold
nactions = 2*10; % 2 motors * 5 speeds
% nstates = 100; % 
% nactions = 20; % 
this_frac = 20;

%% Get environment
mdp = createMDP(nstates, nactions); % initialize MDP

transition_counter = zeros(size(mdp.T));
reward_counter = zeros(size(mdp.R));

% for ii = 1:10^6
%     if ~rem(ii, 100)
%         disp(horzcat('ii: ', num2str(ii/10^6)))
%     end
%     n = round(nstates/this_frac);
%     rl_state = randsample(nstates, n);
%     rl_action = randsample(nactions, n);
%     rl_next_state = randsample(nstates, n);
%     rl_reward = rand < 0.01;
% %     if rl_state > (nstates * 0.9)
% %         rl_reward = 10;
% %     end
%     transition_counter(rl_state, rl_next_state, rl_action) = transition_counter(rl_state, rl_next_state, rl_action) + 1;
%     reward_counter(rl_state, rl_next_state, rl_action) = reward_counter(rl_state, rl_next_state, rl_action) + rl_reward;
% end

files = dir('.\Tuples\*.mat');
nfiles = size(files, 1);
for nfile = 2:nfiles % this will need to be randomized then prioritized
    load(horzcat('.\Tuples\', files(nfile).name))
    if ~rem(nfile, 10)
        disp(horzcat('nfile: ', num2str(nfile/nfiles)))
    end    
    rl_state = rl_tuple{1}; % vis_pref_vals(:), needs to be thresholded around 25 and binarized, can have 1 of 24 states
    this_state = 1 + round(sum(rl_state));
    this_state(this_state > 24) = 24;
    rl_action = rl_tuple{2}; % L&R motor commands (-250 to 250), plot and convert to 1 of 10 states (5 speeds per motor)
    this_action = 1 + round(9 * sum(abs(rl_action)) / 500);
    rl_reward = rl_tuple{3}; % should be clear
    rl_next_state = rl_tuple{4}; % as above
    this_next_state = 1 + round(sum(rl_next_state));
    this_next_state(this_next_state > 24) = 24;    
    transition_counter(this_state, this_next_state, this_action) = ...
        transition_counter(this_state, this_next_state, this_action) + 1;
    reward_counter(this_state, this_next_state, this_action) = ...
        reward_counter(this_state, this_next_state, this_action) + rl_reward;
end
transition_counter = transition_counter ./ sum(transition_counter, 2);
sum(transition_counter(:,:,3), 2)

this_val = sum(isnan(sum(transition_counter, 2)));
this_val = squeeze(this_val);
max(this_val)

% mdp.TerminalStates = ["s2";"s14"];

mdp.T = transition_counter;
mdp.R = reward_counter;

env = rlMDPEnv(mdp);
env.ResetFcn = @() 1;

%% Get agent
obsInfo = rlFiniteSetSpec(1:nstates); % binary thresholded bag-of-features histogram (1000 states total)
actInfo = rlFiniteSetSpec(1:nactions); % 50-levels thresholded motor (2) speaker (5) and lights (3) (500 states total)

qTable = rlTable(obsInfo,actInfo);
critic = rlQValueRepresentation(qTable,obsInfo,actInfo);

opt = rlQAgentOptions;
agent = rlQAgent(critic,opt);

% opt = rlSARSAAgentOptions;
% agent = rlSARSAAgent(critic,opt)

%% Train agent
opt = rlTrainingOptions;
trainOpts.MaxStepsPerEpisode = 50;
trainOpts.MaxEpisodes = 500;
trainStats = train(agent,env,opt);

%% Test :)
% value = getValue(critic,{5},{9})
% action = getAction(agent,{8})





%%% Use this code for continuous agents
% nobsdims = 500;
% nactdims = 10;
% 
% % define a useful state space for SpikerBot navigating the livingroom
% obsInfo = rlNumericSpec([nobsdims 1]);
% actInfo = rlNumericSpec([nactdims 1]);
% 
% % observation path layers
% obsPath = [featureInputLayer(nobsdims, 'Normalization','none','Name','myobs') 
%     fullyConnectedLayer(1,'Name','obsout')];
% 
% % action path layers
% actPath = [featureInputLayer(nactdims, 'Normalization','none','Name','myact') 
%     fullyConnectedLayer(1,'Name','actout')];
% 
% % common path to output layers
% comPath = [additionLayer(2,'Name', 'add')  fullyConnectedLayer(1, 'Name', 'output')];
% 
% % add layers to network object
% net = addLayers(layerGraph(obsPath),actPath); 
% net = addLayers(net,comPath);
% 
% % connect layers
% net = connectLayers(net,'obsout','add/in1');
% net = connectLayers(net,'actout','add/in2');
% 
% % plot network
% plot(net)
% 
% critic = rlQValueRepresentation(net,obsInfo,actInfo, 'Observation',{'myobs'},'Action',{'myact'})

toc
