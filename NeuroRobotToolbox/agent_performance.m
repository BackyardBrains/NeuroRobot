
clear

rand_states = 0;

%% Ontology
classifier_dir_name = '.\Data_1\Rec_2\';
labels = folders2labels(classifier_dir_name);
unique_states = unique(labels);
n_unique_states = length(unique_states);

%% Tuples
tuples_dir_name = 'C:\Users\Christopher Harris\PerformanceData\';
image_dir = dir(fullfile(tuples_dir_name, '**\*.png'));
torque_dir = dir(fullfile(tuples_dir_name, '**\*torques.mat'));
tuples_dir = dir(fullfile(tuples_dir_name, '**\*tuple.mat'));
ntuples = size(tuples_dir, 1);

%% Get states and actions
load livingroom_net
get_states
save('states3', 'states')
get_torques
load('cactions')
get_actions
save('actions3', 'actions')

%% Get tuples
tuples = zeros(ntuples - 5, 3);
for ntuple = 5:ntuples - 1
    if ~rem(ntuple, round((ntuples-1)/10))
        disp(num2str(ntuple/(ntuples-6)))
    end
    this_state = states(ntuple);
    tuples(ntuple - 4, 1) = this_state;
    tuples(ntuple - 4, 2) = states(ntuple + 1);
    tuples(ntuple - 4, 3) = actions(ntuple - 4);
end
ntuples = size(tuples, 1);

%% Get reward
disp('getting rewards')
rewards = zeros(ntuples, 1);
for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end

    if sum(states(ntuple) == [1:4 13:16]) && sum(actions(ntuple) == 1)
        rewards(ntuple) = 1;
    elseif sum(states(ntuple) == [9:12 21:24]) && sum(actions(ntuple) == 1)
        rewards(ntuple) = -1;
    end

end
disp(horzcat('Total reward: ', num2str(sum(rewards))))
disp(horzcat('Rewards per step: ', num2str(sum(rewards)/ntuples)))

%% Plot mdp
figure(11)
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

% subplot(2,2,4)
% title('')

export_fig(horzcat('mdp3_', num2str(date)), '-r150', '-jpg', '-nocrop')
