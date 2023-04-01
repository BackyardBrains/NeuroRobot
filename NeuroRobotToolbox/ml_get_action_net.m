

%% 
agent_name = ax10_edit.String;
if isempty(agent_name) || strcmp(agent_name, 'Enter action net name here')
    ax10_edit.BackgroundColor = [1 0 0];
    pause(0.5)
    ax10_edit.BackgroundColor = [0.94 0.94 0.94];
    error('Set action net name')
end


%%
axes(ax10)
cla
tx10 = text(0.03, 0.5, horzcat('training action nets...'));
drawnow


%% Unpack environment
load(strcat(nets_dir_name, net_name, '-', agent_name, '-env'))
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
qTable = rlTable(obsInfo, actInfo);
critic = rlQValueFunction(qTable,obsInfo,actInfo);

n_unique_states = size(obsInfo.Elements, 1);
n_unique_actions = size(actInfo.Elements, 1);


%% Train Agent 1
agent_opt = rlQAgentOptions;
qOptions = rlOptimizerOptions;
% qOptions.LearnRate = 0.1;
agentOpts.CriticOptimizerOptions = qOptions;
agent = rlQAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 500;
training_opts.MaxStepsPerEpisode = 500;
training_opts.StopTrainingValue = 500;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 200;
if isdeployed
    this_str = 'none';
else
    this_str = 'training-progress';
end
training_opts.Plots = this_str;
training_opts.Verbose = 1;
trainingStats_shallow = train(agent, env, training_opts);

tx10.String = 'Shallow training done. Training deep...';
drawnow

%% Show Agent 1
axes(im_ax1)
cla

hFig=findall(gcf);
hLeg=findobj(hFig(1,1),'type','colorbar');
set(hLeg,'visible','off')
xlabel('')
ylabel('')

hold on
scan_agent
title(horzcat(net_name, ' -RL- ', agent_name))
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
save(horzcat(nets_dir_name, net_name, '-RL-', agent_name, '-ml'), 'agent')


%% Train Agent 2
agent_opt = rlDQNAgentOptions;
agent = rlDQNAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 500;
training_opts.MaxStepsPerEpisode = 500;
training_opts.StopTrainingValue = 500;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 200;
training_opts.UseParallel = 0;
if isdeployed
    this_str = 'none';
else
    this_str = 'training-progress';
end
training_opts.Plots = this_str;
training_opts.Verbose = 1;
trainingStats_deep = train(agent, env, training_opts);


%% Show Agent 2
axes(im_ax2)
cla

hFig=findall(gcf);
hLeg=findobj(hFig(1,1),'type','colorbar');
set(hLeg,'visible','off')
xlabel('')
ylabel('')

hold on
scan_agent
title(horzcat(net_name, ' -DRL- ', agent_name))
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
save(horzcat(nets_dir_name, net_name, '-DRL-', agent_name, '-ml'), 'agent')

tx10.String = horzcat('Shallow and deep training complete');
drawnow

disp('Learning complete')
