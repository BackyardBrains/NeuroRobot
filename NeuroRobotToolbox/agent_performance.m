
%% Performance

clear
clc

reward_states = [10 13];

data_dir_name = 'C:\Users\Christopher Harris\Data_1\';
tuple_dir_name = 'Tuples2\';

labels = folders2labels(strcat(data_dir_name, 'Classifier\'));
unique_states = unique(labels);
n_unique_states = length(unique_states);

image_dir = dir(fullfile(strcat(data_dir_name, tuple_dir_name), '**\*.png'));
torque_dir = dir(fullfile(strcat(data_dir_name, tuple_dir_name), '**\*torques.mat'));
ntuples = size(torque_dir, 1);


%% Get states
load(strcat(data_dir_name, 'circle_net'))
get_states
save(strcat(data_dir_name, 'states'), 'states')
load(strcat(data_dir_name, 'states'))

%% Get actions
get_torques
quiescence = ~sum(abs(torque_data')); % For agents

%% Get tuples
tuples = zeros(ntuples - 6, 3);
for ntuple = 6:ntuples - 1
    tuples(ntuple - 5, 1) = states(ntuple - 5);
    tuples(ntuple - 5, 2) = states(ntuple);
    tuples(ntuple - 5, 3) = quiescence(ntuple - 5);
end
ntuples = size(tuples, 1);

%% Get reward
disp('getting rewards')
rewards = zeros(ntuples, 1);
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end
    if sum(states(ntuple) == reward_states) && sum(quiescence(ntuple) == mode(quiescence))
        rewards(ntuple) = 1;
    else
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
ylabel('Count')

subplot(2,2,2)
histogram(quiescence, 'binwidth', .25)
title('Quiesence (goal action)')
xlabel('Quiesence')
ylabel('Count')

subplot(2,2,3:4)
plot(rewards)
axis tight
title('Reward')

export_fig(horzcat(tuple_dir_name(1:end-1), '_mdp_', num2str(date)), '-r150', '-jpg', '-nocrop')
