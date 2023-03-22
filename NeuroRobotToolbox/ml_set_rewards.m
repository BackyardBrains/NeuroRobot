

%% Set rewards
% reward_states = [9 10];
reward_states = str2num(ax9_edit.String);
if isempty(reward_states)
    error('No rewards!')
end
agent_name = 'agent1'; % note: also assigned in neurorobot.m


%% Process rewards
axes(ax9)
cla
tx9 = text(0.03, 0.5, 'Creating reward landscape ');
drawnow


disp('Getting reward...')
rcount = 0;
rewards = zeros(ntuples, 1) - 1;
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/5))
        disp(num2str(ntuple/ntuples))
    end
    if sum(tuples(ntuple, 1) == reward_states) && sum(tuples(ntuple, 3) == mode(actions))
        rewards(ntuple) = 1;
        rcount = rcount + 1;
    end
end
disp(horzcat('Total reward count: ', num2str(sum(rcount))))
disp(horzcat('Rewards per step: ', num2str(sum(rewards)/ntuples)))

reward_counter = zeros(size(mdp.R)) - 1;
reward_counter(:,reward_states, mode(actions)) = 1;
mdp.R = reward_counter;
disp(horzcat('total reward: ', num2str(sum(reward_counter(:)))))
save(strcat(nets_dir_name, net_name, '-', agent_name, '-mdp'), 'mdp')
disp('Rewards ready')

env = rlMDPEnv(mdp);
save(strcat(nets_dir_name, net_name, '-', agent_name, '-env'), 'env')
validateEnvironment(env)
disp('Environment ready')


%% Output
tx9.String = 'Ready to train';
drawnow

axes(im_ax2)
cla
plot(rewards)
axis tight
title('Rewards')
xlabel('Time (steps)')
ylabel('Reward value')


