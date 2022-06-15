
agent_opt = rlQAgentOptions;
agent_opt.DiscountFactor = 0.99;
agent = rlQAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 500;
training_opts.MaxStepsPerEpisode = 100;
training_opts.StopTrainingCriteria = "EpisodeCount";
training_opts.ScoreAveragingWindowLength = 10;
trainingStats_shallow = train(agent,env, training_opts);

figure(11)
clf
scan_agent
title('Shallow agent')