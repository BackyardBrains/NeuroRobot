


%% scaling factor
scale_f = 10 * learn_speed;
disp(horzcat('main ML parameter scaled to: ', num2str(scale_f)))


%%
axes(ml_train2_status)
cla
tx10 = text(0.03, 0.5, horzcat('Training decision net...'));
drawnow


%% Unpack environment
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
qTable = rlTable(obsInfo, actInfo);
critic = rlQValueFunction(qTable,obsInfo,actInfo);

n_unique_states = size(obsInfo.Elements, 1);
n_unique_actions = size(actInfo.Elements, 1);

% delete(gcp('nocreate'))
% parpool

%% Train Agent 2
agent_opt = rlDQNAgentOptions;
% agent_opt.DiscountFactor = 0.1;
agent = rlDQNAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = scale_f * 2;
training_opts.MaxStepsPerEpisode = scale_f;
training_opts.StopTrainingValue = scale_f * 10;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = scale_f / 5;
training_opts.UseParallel = 0;
if isdeployed
    this_str = 'none';
else
    this_str = 'training-progress';
end
training_opts.Plots = this_str;
training_opts.Verbose = 1;

trainingStats_deep = train(agent, env, training_opts);
save(horzcat(nets_dir_name, state_net_name, '-go2-', action_net_name, '-ml'), 'agent')


%% Show Agent
axes(im_ax1)
cla

hold on
scan_agent
title(horzcat(state_net_name, '-', action_net_name))
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')

tx10.String = horzcat('Finished training action network');
drawnow

disp('Finished training decision network')
