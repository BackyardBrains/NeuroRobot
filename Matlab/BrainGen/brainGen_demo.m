

%% Close and clear
close all
clear


%% Load indented activity
load intended_activity


%% Specify number of neurons
nneurons = 10;


%% Generate brain that produces intended activity
[a, b, c, d, connectome, max_corr] = brainGen(intended_activity, nneurons);
% load bursting_brain


%% Get mean brain activity
nsteps = size(intended_activity, 1);
spike_log = brainSim(a, b, c, d, connectome, nsteps);
mean_activity = mean(spike_log);
mean_activity = mean_activity - min(mean_activity);
mean_activity = mean_activity / max(mean_activity);
% r = corr(mean_activity', intended_activity);
r = 1 / sum(abs(mean_activity' - intended_activity));

figure(1)
clf
set(gcf, 'position', [200 400 855 277], 'color', 'w')
plot(mean_activity, 'color', [0.2 0.4 0.8])
hold on
plot(intended_activity, 'color', [0.8 0.4 0.2])
ylim([0 1.3])
legend('Actual network activity', 'Intended network activity')
title(horzcat('Actual vs intended network activity, correlation = ', num2str(r)))
xlabel('Time')

