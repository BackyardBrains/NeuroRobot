

%% Set rewards
list_of_states = str2num(ml_goals_edit.String);
if isempty(list_of_states) || sum(isnan(list_of_states))
    ml_goals_edit.BackgroundColor = [1 0 0];
    pause(0.5)
    ml_goals_edit.BackgroundColor = [0.94 0.94 0.94];
    error('Enter at least one goal state')
end

reward_states = list_of_states(sign(list_of_states) == 1);

if sum(sign(list_of_states) == -1)
    bad_states = list_of_states(sign(list_of_states) == -1);
else
    bad_states = [];
end

reward_action = mode(actions);
disp(horzcat('reward action (mode) = ', num2str(reward_action)))
disp(horzcat('reward action torque: ',  num2str(round(mean(torque_data(actions == reward_action, :), 1)))))

% bad_action = find(sum(motor_combs, 2) < 0);
% disp(horzcat('bad action (backward) = ', num2str(bad_action)))
% disp(horzcat('bad action torque: ',  num2str(round(mean(torque_data(actions == bad_action, :), 1)))))

%% Create reward landscape
disp('Creating reward landscape...')
axes(ml_train2_status)
cla
tx9 = text(0.03, 0.5, 'Creating reward landscape ');
drawnow

reward_counter = zeros(size(mdp.R));
reward_counter(:, :, bad_action) = -1;
if ~isempty(reward_states)
    reward_counter(:, reward_states, reward_action) = 5;
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

