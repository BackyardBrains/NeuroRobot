


clear
clc

rand_states = 0;

%% Ontology
classifier_dir_name = '.\Data_1\Rec_2\';
labels = folders2labels(classifier_dir_name);
unique_states = unique(labels);
n_unique_states = length(unique_states);

%% Tuples
tuples_dir_name = 'C:\Users\Christopher Harris\PerformanceData\';
% image_dir = dir(fullfile(tuples_dir_name, '**\*.png'));
% serial_dir = dir(fullfile(tuples_dir_name, '**\*serial_data.mat'));
torque_dir = dir(fullfile(tuples_dir_name, '**\*torques.mat'));
tuples_dir = dir(fullfile(tuples_dir_name, '**\*tuples.mat'));
ntuples = size(tuples_dir, 1);

%% Get states and actions
disp(horzcat('getting ', num2str(ntuples), ' torques'))
states = zeros(ntuples, 1);
actions = zeros(ntuples, 1);
for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end

    tuples_fname = horzcat(tuples_dir(ntuple).folder, '\', tuples_dir(ntuple).name);
    load(tuples_fname)

    states(ntuple) = tuple(1);
    actions(ntuple) = tuple(2);

end

%% Get reward
disp('getting rewards')
rewards = zeros(ntuples, 1);
for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end

    if sum(states(ntuple) == [1:4 13:16]) && sum(action(ntuple) == 1)
        rewards(ntuple) = 1;
    elseif sum(states(ntuple) == [9:12 21:24]) && sum(action(ntuple) == 1)
        rewards(ntuple) = -1;
    end


end

%% Plot mdp
figure(10)
clf
set(gcf, 'position', [100 50 1280 720], 'color', 'w')

subplot(2,2,1)
histogram(states, 'binwidth', .25)
title('States')
xlabel('State')
ylabel('States')

subplot(2,2,2)
histogram(actions, 'binwidth', .25)
title('Actions')
xlabel('Action')
ylabel('Actions')

subplot(2,2,3:4)
plot(rewards)
title('Reward')

subplot(2,2,4)
title('')

% export_fig(horzcat('rmdp_', num2str(date)), '-r150', '-jpg', '-nocrop')
