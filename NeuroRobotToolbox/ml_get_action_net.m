


%% scaling factor
scale_f = 100;
disp(horzcat('main ML parameter scaled to: ', num2str(scale_f)))


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
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
qTable = rlTable(obsInfo, actInfo);
critic = rlQValueFunction(qTable,obsInfo,actInfo);

n_unique_states = size(obsInfo.Elements, 1);
n_unique_actions = size(actInfo.Elements, 1);


%% Train Agent 1
agent_opt = rlQAgentOptions;
agent_opt.DiscountFactor = 0.1;
agent = rlQAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = scale_f;
training_opts.MaxStepsPerEpisode = scale_f;
training_opts.StopTrainingValue = scale_f;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = scale_f/5;
if isdeployed
    this_str = 'none';
else
    this_str = 'training-progress';
end
training_opts.Plots = this_str;
training_opts.Verbose = 1;

trainingStats_shallow = train(agent, env, training_opts);
save(horzcat(nets_dir_name, net_name, '-RL-', agent_name, '-ml'), 'agent')

tx10.String = 'Shallow training done. Training deep...';
drawnow

%% Show Agent 1
delete(im_ax1)
im_ax1_pos = [0.63 0.54 0.3 0.35];
im_ax1_colb_pos = [0.94 0.54 0.02 0.35];
im_ax1 = axes('position', im_ax1_pos);
set(im_ax1, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col)

axes(im_ax1)
cla

hold on
scan_agent
title(horzcat(net_name, ' -RL- ', agent_name))
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')


%% Train Agent 2
agent_opt = rlDQNAgentOptions;
agent_opt.DiscountFactor = 0.1;
agent = rlDQNAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = scale_f;
training_opts.MaxStepsPerEpisode = scale_f;
training_opts.StopTrainingValue = scale_f;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = scale_f/5;
training_opts.UseParallel = 0;
if isdeployed
    this_str = 'none';
else
    this_str = 'training-progress';
end
training_opts.Plots = this_str;
training_opts.Verbose = 1;

trainingStats_deep = train(agent, env, training_opts);
save(horzcat(nets_dir_name, net_name, '-DRL-', agent_name, '-ml'), 'agent')


%% Show Agent 2
delete(im_ax2)
im_ax2_pos = [0.63 0.08 0.3 0.35];
im_ax2_colb_pos = [0.94 0.08 0.02 0.35];
im_ax2 = axes('position', im_ax2_pos);
set(im_ax2, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col)

axes(im_ax2)
cla

hold on
scan_agent
title(horzcat(net_name, ' -DRL- ', agent_name))
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')

tx10.String = horzcat('Shallow and deep training complete');
drawnow

disp('Learning complete')
