
% Training works

agent_opt = rlQAgentOptions;
agent_opt.DiscountFactor = 0.1;
agent = rlQAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 1000;
training_opts.MaxStepsPerEpisode = 100;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 10;
trainingStats_Shallow = train(agent,env, training_opts);
save('agent_4', 'agent')


