

close all
clear


%% Environment
GW = createGridWorld(4,4);
GW.CurrentState = '[1,1]';
updateStateTranstionForObstacles(GW)
nS = numel(GW.States);
nA = numel(GW.Actions);
GW.R = -1*ones(nS,nS,nA);
GW.R(:,16,:) = 10;
env = rlMDPEnv(GW);
obsInfo = getObservationInfo(env); % rlFiniteSetSpec(1:25)
actInfo = getActionInfo(env); % rlFiniteSetSpec(1:4)


%% Data logger
flgr = rlDataLogger;
flgr.EpisodeFinishedFcn = @myEpisodeFinishedFcn;


%% Initialize Qagent
qTable = rlTable(obsInfo, actInfo);
qFcnAppx = rlQValueFunction(qTable, obsInfo, actInfo);
qFcnAppx.UseDevice = 'gpu';
qAgent = rlQAgent(qFcnAppx);
qAgent.AgentOptions.EpsilonGreedyExploration.Epsilon = .04;
qAgent.AgentOptions.CriticOptimizerOptions.LearnRate = 0.1;


%% Initialize training
trainOpts = rlTrainingOptions;
trainOpts.MaxStepsPerEpisode = 10;
trainOpts.MaxEpisodes= 100;
trainOpts.StopTrainingCriteria = "none";
% trainOpts.StopTrainingValue = 11;
trainOpts.ScoreAveragingWindowLength = 30;
% trainOpts.Plots="none";


%% Train
rmdir logs s
trainingStats = train(qAgent,env,trainOpts,Logger=flgr);


%% Validate
figure(1)
clf
plot(env)
env.Model.Viewer.ShowTrace = true;
env.Model.Viewer.clearTrace;
qexp = sim(qAgent,env);
disp(horzcat('Simulated Q agent reward = ', num2str(sum(qexp.Reward.Data))))
drawnow


%% Train agent offline
delete('./logs/info.mat')
fds = fileDatastore("./logs", "ReadFcn", @ml_readFcn);
nfiles = length(fds.Files);
buffer = rlReplayMemory(obsInfo,actInfo);


%%
clear exp
for nfile = 1:nfiles
    data = read(fds);
    exp(nfile).Observation = data.Observation;
    exp(nfile).Action = data.Action;
    exp(nfile).Reward = data.Reward;
    exp(nfile).NextObservation = data.NextObservation;
    exp(nfile).IsDone = 0;
end

validateExperience(buffer,exp)
append(buffer,exp);


%% Train neural agent from data
criticNet = [
    featureInputLayer(prod(obsInfo.Dimension))
    fullyConnectedLayer(24)
    reluLayer
    fullyConnectedLayer(48)
    reluLayer
    fullyConnectedLayer(numel(actInfo.Elements))
    ];
criticNet = dlnetwork(criticNet);
summary(criticNet)
critic = rlVectorQValueFunction(criticNet,obsInfo,actInfo);
% criticOpts = rlOptimizerOptions(LearnRate=0.001,GradientThreshold=1);
agentOptions = rlDQNAgentOptions;
% CriticOptimizerOptions=criticOpts,...
% ExperienceBufferLength=3000,... 
% UseDoubleDQN=false);
agent = rlDQNAgent(critic,agentOptions);
% agent.AgentOptions.EpsilonGreedyExploration.Epsilon = .04;
% agent.AgentOptions.CriticOptimizerOptions.LearnRate = 0.01;
tfdOpts = rlTrainingFromDataOptions;
tfdOpts.StopTrainingCriteria = "none";
tfdOpts.ScoreAveragingWindowLength = 10;
tfdOpts.MaxEpochs = 200;
tfdOpts.NumStepsPerEpoch = 10;
% fds = fileDatastore("./logs", "ReadFcn", @ml_readFcn);
agent.ExperienceBuffer = buffer;
trainFromData(agent);

figure(2)
clf
plot(env)
env.Model.Viewer.ShowTrace = true;
env.Model.Viewer.clearTrace;
dqexp = sim(agent,env);
disp(horzcat('Simulated deep Q agent reward = ', num2str(sum(dqexp.Reward.Data))))
drawnow


%% myEpisodeFinishedFcn
function dataToLog = myEpisodeFinishedFcn(data)
    dataToLog.Experience = data.Experience;
end




