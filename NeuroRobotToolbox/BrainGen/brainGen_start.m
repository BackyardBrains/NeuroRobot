

% This script uses optimization algorithms to search for a brain whose
% behavior matches get_intended_activity

close all
clear
tic

%% Settings
brain_name = 'spikebursting_ga_1';
get_nneurons
get_intended_activity

figure(100); plot(intended_activity); title('Intended activity'); xlabel('Time (msec')

% approach = 'fmincon';
% approach = 'patternsearch';
approach = 'particleswarm';
% approach = 'ga';


%% Run the search
[brain_vector, fval, exitflag] = generate_brain(approach);


%% Unpack and save brain
brain_matrix = reshape(brain_vector, [nneurons + 4, nneurons]);
a = brain_matrix(1,:)'; b = brain_matrix(2,:)'; c = brain_matrix(3,:)'; d = brain_matrix(4,:)';
connectome = zeros(length(a));
for nneuron = 1:nneurons
    connectome(nneuron,:) = brain_matrix(4+nneuron,:);
end
save_to_runnable_brain % This needs unpacked variable b
plot_brain % This needs many of the vars unpacked by save_to_runnable_brain


%% Resimulate brain and compare intended activity to actual
nsteps = length(intended_activity);
[mean_activity, spike_log] = run_brain(a, b, c, d, connectome, nsteps);
this_error = sum(abs(mean_activity - intended_activity));
plot_intended_vs_actual


%% Exit
disp(horzcat('Brain generation completed in ', num2str(round(toc)), ' seconds'))
