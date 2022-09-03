
%% Performance

clear
% clc

reward_states = [1 7 8 19 24];

data_dir_name = 'C:\Users\Christopher Harris\Dataset 1\';
% tuple_dir_name = 'Tuples1\';
tuple_dir_name = '';

load(strcat(data_dir_name, 'labels.mat'))
unique_states = unique(labels);
n_unique_states = length(unique_states);

image_dir = dir(fullfile(strcat(data_dir_name, tuple_dir_name), '**\Rec*\*.png'));
torque_dir = dir(fullfile(strcat(data_dir_name, tuple_dir_name), '**\Rec*\*torques.mat'));
ntorques = size(torque_dir, 1);
nimages = size(image_dir, 1);
ntuples = size(torque_dir, 1);

%% Get states
load(strcat(data_dir_name, 'randomwalk_net'))
get_states

%% Get actions
get_torques

%% Get reward
disp('getting rewards')
rewards = zeros(ntuples, 1);
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end
    if sum(states(ntuple) == reward_states) && ~sum(abs(torque_data(ntuple, :)))
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
histogram(torque_data, 'binwidth', 5)
set(gca, 'yscale', 'log')
title('Quiesence (goal action)')
xlabel('Quiesence')
ylabel('Count')

subplot(2,2,3:4)
area(rewards)
axis tight
title('Reward')

export_fig(horzcat(tuple_dir_name(1:end-1), '_mdp_', num2str(date)), '-r150', '-jpg', '-nocrop')
