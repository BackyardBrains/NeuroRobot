
agent_opt = rlDQNAgentOptions;
% agent_opt.DiscountFactor = 0.99;
% agent_opt.EpsilonGreedyExploration.Epsilon = 1;
% agent_opt.EpsilonGreedyExploration.EpsilonMin = 0.01;
% agent_opt.EpsilonGreedyExploration.EpsilonDecay = 0.005;

agent = rlDQNAgent(critic, agent_opt);

training_opts = rlTrainingOptions;
% training_opts.MaxEpisodes = 1000;
% training_opts.MaxStepsPerEpisode = 500;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 10;
training_opts.UseParallel = 1;

trainingStats_deep = train(agent, env, training_opts);

figure(12)
clf
scan_agent
title('Deep agent')

