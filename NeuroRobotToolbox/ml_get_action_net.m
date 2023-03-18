
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
training_opts.MaxStepsPerEpisode = 200;
training_opts.StopTrainingValue = 200;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 100;
if isdeployed
    this_str = 'none';
else
    this_str = 'training-progress';
end
training_opts.Plots = this_str;
trainingStats_shallow = train(agent, env, training_opts);

tx10.String = horzcat(net_name, '-RL-', agent_name, ' trained successfully. training DRL agent...');
drawnow

%% Show Agent 1
% figure(11)
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
% export_fig(horzcat(workspace_dir_name, net_name, '-RL-', agent_name), '-r150', '-jpg', '-nocrop')
save(horzcat(nets_dir_name, net_name, '-RL-', agent_name), 'agent')


%% Train Agent 2
agent_opt = rlDQNAgentOptions;
agent = rlDQNAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 500;
training_opts.MaxStepsPerEpisode = 200;
training_opts.StopTrainingValue = 200;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 100;
training_opts.UseParallel = 0;
if isdeployed
    this_str = 'none';
else
    this_str = 'training-progress';
end
training_opts.Plots = this_str;
trainingStats_deep = train(agent, env, training_opts);


%% Show Agent 2
% figure(12)
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
% export_fig(horzcat(workspace_dir_name, net_name, '-DRL-', agent_name), '-r150', '-jpg', '-nocrop')
save(horzcat(nets_dir_name, net_name, '-DRL-', agent_name), 'agent')

tx10.String = horzcat(net_name, '-DRL-', agent_name, ' trained successfully. Deep Learning Experiment complete!');
drawnow
