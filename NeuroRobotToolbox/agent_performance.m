
%% Performance

clear
% clc

reward_states = [1 7 8 19 24];

data_dir_name = 'C:\Users\Christopher Harris\Dataset 1\';
tuple_dir_name = '';

load(strcat(data_dir_name, 'labels.mat'))
unique_states = unique(labels);
n_unique_states = length(unique_states);

% image_dir = dir(fullfile(strcat(data_dir_name, tuple_dir_name), '**\Rec*\*.png'));
% torque_dir = dir(fullfile(strcat(data_dir_name, tuple_dir_name), '**\Rec*\*torques.mat'));
% image_dir = dir(fullfile(strcat(data_dir_name, tuple_dir_name), '**\Agent*\*.png'));
torque_dir = dir(fullfile(strcat(data_dir_name, tuple_dir_name), '**\Agent*\*torques.mat'));
ntorques = size(torque_dir, 1);
% nimages = size(image_dir, 1);
ntuples = size(torque_dir, 1);

retina_movie5_setup

%% Get states
% load(strcat(data_dir_name, 'randomwalk_net'))
% get_states
% save(strcat(data_dir_name, 'states2'), 'states')
load(strcat(data_dir_name, 'states2'))

%% Get actions
% get_torques
% save(strcat(data_dir_name, 'torque_data2'), 'torque_data')
load(strcat(data_dir_name, 'torque_data2'))

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
ylabel('#')

subplot(2,2,2)
histogram(torque_data, 'binwidth', 5)
set(gca, 'yscale', 'log')
title('Torques')
xlabel('Torque')
ylabel('#')

subplot(2,2,3:4)
area(rewards)
xlabel('Time (steps)')
axis tight
title('Reward')

export_fig(horzcat('mdp2_', num2str(date)), '-r150', '-jpg', '-nocrop')

%% Get steps to reward state
nruns = 1000;
disp('getting steps to reward')
steps_to_reward = zeros(n_unique_states, nruns);
for start_state = 1:n_unique_states
    disp(horzcat('start_state = ', num2str(start_state)))
    inds = find(states == start_state);
    if ~isempty(inds) && ~sum(start_state == reward_states)
        for nrun = 1:nruns
            this_start_ind = randsample(inds, 1);
            xx = sum(states(this_start_ind:end)' == reward_states');
            this_many_steps = find(xx, 1, 'first');
            if ~isempty(this_many_steps)
                disp(horzcat('this_many_steps = ', num2str(this_many_steps)))
                steps_to_reward(start_state, nrun) = this_many_steps;
%                 retina_movie5
            end
        end
    end
end
save(strcat(data_dir_name, 'steps_to_reward2'), 'steps_to_reward')
load(strcat(data_dir_name, 'steps_to_reward2'))

close(vid_writer)

%%
load(strcat(data_dir_name, 'steps_to_reward'))
steps_to_reward(steps_to_reward == 0) = NaN;
figure(5)
clf
plot(steps_to_reward, 'color', [0.2 0.4 0.8])
plot(steps_to_reward, 'color', [0.8 0.4 0.2])
plot(nanmean(steps_to_reward'), 'color', [0.2 0.4 0.8])
hold on
load(strcat(data_dir_name, 'steps_to_reward2'))
steps_to_reward(steps_to_reward == 0) = NaN;
plot(nanmean(steps_to_reward'), 'color', [0.8 0.4 0.2])
axis tight
set(gcf, 'color', 'w')
title('Steps to reach reward state')
xlabel('Initial state')
ylabel('Steps (average)')