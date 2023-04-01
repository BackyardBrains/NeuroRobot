

%% Set rewards
list_of_states = str2num(ax9_edit.String);
if isempty(list_of_states) || sum(isnan(list_of_states))
    ax9_edit.BackgroundColor = [1 0 0];
    pause(0.5)
    ax9_edit.BackgroundColor = [0.94 0.94 0.94];
    error('Enter at least one goal state')
end
reward_states = list_of_states(sign(list_of_states) == 1);
bad_states = list_of_states(sign(list_of_states) == -1);
disp(horzcat('n reward states = ', num2str(length(reward_states))))
disp(horzcat('n bad states = ', num2str(length(bad_states))))


%% Manually set reward action
% reward_action = n_unique_actions; % stand still
reward_action = 3; % forward
disp(horzcat('reward action = ', num2str(reward_action)))


%% Create reward landscape
disp('Creating reward landscape...')
axes(ax9)
cla
tx9 = text(0.03, 0.5, 'Creating reward landscape ');
drawnow

reward_counter = zeros(size(mdp.R));
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

% Save environment
save(strcat(nets_dir_name, net_name, '-', agent_name, '-env'), 'env')


%% Output
tx9.String = 'Ready to train';
drawnow

% axes(im_ax2)
% cla
% plot(rewards)
% axis tight
% title('Rewards')
% xlabel('Time (steps)')
% ylabel('Reward value')


