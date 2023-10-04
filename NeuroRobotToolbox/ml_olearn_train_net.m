


%% Set rewards
list_of_states = str2num(olearn_goal_edit.String);
if isempty(list_of_states) || sum(isnan(list_of_states))
    olearn_goal_edit.BackgroundColor = [1 0 0];
    pause(0.5)
    olearn_goal_edit.BackgroundColor = [0.94 0.94 0.94];
    error('Enter at least one goal state')
end
reward_states = list_of_states(sign(list_of_states) == 1);
bad_states = list_of_states(sign(list_of_states) == -1);

reward_action = mode(actions);
disp(horzcat('reward action (mode) = ', num2str(reward_action)))


%% Create reward landscape
disp('Creating reward landscape...')
axes(olearn_train_status_ax)
cla
tx9 = text(0.03, 0.5, 'Creating reward landscape ');
drawnow

reward_counter = zeros(size(mdp.R));
reward_counter(:, :, reward_action) = -1; % Skip this?
if ~isempty(reward_states)
    reward_counter(:, reward_states, reward_action) = 1;
end
if ~isempty(bad_states)
    reward_counter(:, -bad_states, reward_action) = -1;
end
mdp.R = reward_counter;
disp(horzcat('total reward: ', num2str(sum(reward_counter(:)))))
disp('Rewards ready')

env = rlMDPEnv(mdp);
validateEnvironment(env)
disp('Environment ready')


%% Output
tx9.String = 'Ready to train';
drawnow


%% Get speed
if olearn_speed_select.Value == 1 % Slow
    olearn_speed = 1;
elseif olearn_speed_select.Value == 2 % Fast
    olearn_speed = 0.1;
end

%% scaling factor
scale_f = 300 * olearn_speed;
disp(horzcat('main ML parameter scaled to: ', num2str(scale_f)))


%% 
agent_name = olrean_name_edit.String;
if isempty(agent_name) || strcmp(agent_name, 'Enter action net name here')
    olrean_name_edit.BackgroundColor = [1 0 0];
    pause(0.5)
    olrean_name_edit.BackgroundColor = [0.94 0.94 0.94];
    error('Set action net name')
end


%%
axes(olearn_train_status_ax)
cla
tx10 = text(0.03, 0.5, horzcat('Training action net...'));
drawnow


%% Unpack environment
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
qTable = rlTable(obsInfo, actInfo);
critic = rlQValueFunction(qTable,obsInfo,actInfo);

n_unique_states = size(obsInfo.Elements, 1);
n_unique_actions = size(actInfo.Elements, 1);


%% Train Agent
agent_opt = rlDQNAgentOptions;
% agent_opt.DiscountFactor = 0.1;
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
save(horzcat(nets_dir_name, net_name, '-', agent_name, '-ml'), 'agent')


%% Show Agent 2
delete(im_ax1)

im_ax1_pos = [0.16 0.15 0.31 0.3];
im_ax1 = axes('position', im_ax1_pos, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col);

axes(im_ax1)
hold on
scan_agent
title(horzcat(net_name, '- ', agent_name))
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')

tx10.String = horzcat('Learning complete');
drawnow

disp('Learning complete')
