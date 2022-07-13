


gw = createGridWorld(5,5);
nstates = numel(gw.States);
nactions = numel(gw.Actions);
for nstate = 1:nstates
    for naction = 1:nactions
        this_array = gw.T(nstate, :, naction);
        this_array = this_array(randperm(length(this_array)));
        gw.T(nstate, :, naction) = this_array;
    end
end
gw.R = -1*ones(nstates,nstates,nactions);
gw.R(25, 25, :) = 10;
env = rlMDPEnv(gw);

validateEnvironment(env)
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
qTable = rlTable(obsInfo, actInfo);
critic = rlQValueFunction(qTable,obsInfo,actInfo);

% load('basicGWQAgent.mat','qAgent')
% agent = qAgent;

agent_opt = rlQAgentOptions;
agent = rlQAgent(critic, agent_opt);

training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 100;
training_opts.MaxStepsPerEpisode = 50;
training_opts.StopTrainingValue = 1000;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 5;
trainingStats_shallow = train(agent,env, training_opts);
