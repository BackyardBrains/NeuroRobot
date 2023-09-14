

%% Set rewards
list_of_states = str2num(rl_edit2_goal.String);
if isempty(list_of_states) || sum(isnan(list_of_states))
    rl_edit2_goal.BackgroundColor = [1 0 0];
    pause(0.5)
    rl_edit2_goal.BackgroundColor = [0.94 0.94 0.94];
    error('Enter at least one goal state')
end
reward_states = list_of_states(sign(list_of_states) == 1);
bad_states = list_of_states(sign(list_of_states) == -1);

% reward_action = str2num(ax9_edit2.String);
reward_action = 1;
% if isempty(reward_action) || isnan(reward_action) || length(reward_action) > 1
%     ax9_edit2.BackgroundColor = [1 0 0];
%     pause(0.5)
%     ax9_edit2.BackgroundColor = [0.94 0.94 0.94];
%     error('Enter one goal action')
% end
disp(horzcat('reward action = ', num2str(reward_action)))


%% Create reward landscape
disp('Creating reward landscape...')
axes(rl_out2)
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

