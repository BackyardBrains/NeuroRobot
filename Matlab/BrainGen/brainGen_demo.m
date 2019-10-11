
% This script applies different optimization algorithms to search for a brain whose
% behavior matches get_intended_activity

close all
clear

nneurons = 10;
get_intended_activity

[a, b, c, d, connectome] = brainGen(intended_activity, nneurons);

nsteps = size(intended_activity, 1);
spike_log = brainSim(a, b, c, d, connectome, nsteps);
mean_activity = mean(spike_log);
mean_activity = mean_activity - min(mean_activity);
mean_activity = mean_activity / max(mean_activity);
this_error = sum((mean_activity' - intended_activity).^2);

plot_intended_vs_actual
