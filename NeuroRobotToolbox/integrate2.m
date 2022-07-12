
close all
clear
clc

%%
load('states_rand')
load('torque_data_rand')
load('actions_rand')
load('mdp_rand')
load('transition_counter_save_rand')

rstates = states;
rtorque_data = torque_data;
ractions = actions;
rmdp = mdp;
rtransition_counter_save = transition_counter_save;

%%
load('states')
load('torque_data')
load('actions')
load('mdp')
% load('transition_counter_save')

%%
figure(1)
clf
subplot(1,2,1)
histogram(rstates, 'facecolor', [0.2 0.4 0.8])
hold on
histogram(states, 'facecolor', [0.2 0.8 0.2])
title('States')
subplot(1,2,2)
histogram(ractions, 'facecolor', [0.2 0.4 0.8])
hold on
histogram(actions, 'facecolor', [0.2 0.8 0.2])
title('Actions')

%%
figure(2)
clf
subplot(1,2,1)
imagesc(squeeze(mean(rmdp.T, 3)), [0 0.25])
title('Transitions (rand)')
subplot(1,2,2)
imagesc(squeeze(mean(mdp.T, 3)), [0 0.25])
title('Transitionss')

%%
% load('mdp')
n_unique_states = 24;
n_unique_actions = 5;
env = rlMDPEnv(mdp);
env.ResetFcn = @() randsample(n_unique_states, 1);
validateEnvironment(env)
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
qTable = rlTable(obsInfo, actInfo);
critic = rlQValueFunction(qTable,obsInfo,actInfo);
sum(mdp.R(:))


%% Agent 1 (Q)
agent_opt = rlQAgentOptions;
% agent_opt.DiscountFactor = 0.1;
qOptions = rlOptimizerOptions;
% qOptions.LearnRate = 1;
agentOpts.CriticOptimizerOptions = qOptions;
agent = rlQAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 100;
training_opts.MaxStepsPerEpisode = 100;
training_opts.StopTrainingValue = 500000;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 5;
trainingStats_shallow = train(agent,env, training_opts);
figure(11)
clf
set(gcf, 'color', 'w')
scan_agent
ylim([0 n_unique_states + 1])
title('Agent 1')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat('agent1_', num2str(date), '_net'), '-r150', '-jpg', '-nocrop')
save('agent1_', 'agent')

%% Agent 2 (Deep Q)
agent_opt = rlDQNAgentOptions;
agent_opt.DiscountFactor = 0.99;
% agent_opt.EpsilonGreedyExploration.Epsilon = 0.1;
% agent_opt.EpsilonGreedyExploration.EpsilonMin = 0.01;
% agent_opt.EpsilonGreedyExploration.EpsilonDecay = 0.5;
agent = rlDQNAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 100;
training_opts.MaxStepsPerEpisode = 20;
training_opts.StopTrainingValue = 500000;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 5;
training_opts.UseParallel = 1;
trainingStats_deep = train(agent, env, training_opts);
figure(12)
clf
set(gcf, 'color', 'w')
scan_agent
ylim([0 n_unique_states + 1])
title('Agent 2')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat('agent2_', num2str(date), '_net'), '-r150', '-jpg', '-nocrop')
save('agent2', 'agent')

