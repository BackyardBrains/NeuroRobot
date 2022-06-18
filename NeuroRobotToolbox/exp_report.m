


%% Save
save('rl_exp_data', 'rl_exp_data')


%% States
figure(11)
clf
histogram(rl_exp_data(:,1))
title('States observed during the experiment')

%% Actions
figure(12)
clf
histogram(rl_exp_data(:,2))
title('Actions performed during the experiment')

%% Reward
figure(13)
clf
rl_a = rl_exp_data(:,3);
rl_a(rl_a == Inf) = 0;
rl_exp_data(:,3) = rl_a;
rl_r = rl_exp_data(:,3);
rl_r = rl_r - min(rl_r);
rl_r = rl_r / max(rl_r);
subplot(2,1,1)
plot(rl_r)
xlabel('Time')
ylabel('Reward')
subplot(2,1,2)
histogram(rl_r)
xlabel('Reward amplitude')
ylabel('Count')
title('Rewards obtained during the experiment')
