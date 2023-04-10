
% markov injection (assumes you already ran neurorobot.m)

net_name = 'livingroom'
% tv = [4 8 16 18 19 32 40 48]
% bookshelf = [7 13 14 17 22 26 27 28 29 31 33 38 39 47 54]
% hallway = [4 20 36 46]
% fix the motor less than 10 issue too

load(horzcat(nets_dir_name, net_name, '-states'))
load(horzcat(nets_dir_name, net_name, '-torque_data'))
ntuples = size(torque_data, 1);
disp(horzcat('ntuples: ', num2str(ntuples)))

load(strcat(nets_dir_name, net_name, '-net'))
load(strcat(nets_dir_name, net_name, '-labels'))
n_unique_states = length(labels);
disp(horzcat('n unique states: ', num2str(n_unique_states)))

n_unique_actions = 9;
rng(1)
actions = kmeans(torque_data, n_unique_actions);
still = abs(torque_data(:,1)) < 10 & abs(torque_data(:,2)) < 10;
disp(horzcat('n still actions: ', num2str(sum(still))))
actions(still) = n_unique_actions + 1;
if ~sum(actions == 1)
    actions = actions - 1;
end

% load(strcat(nets_dir_name, net_name, '-actions'))
n_unique_actions = length(unique(actions));
disp(horzcat('n unique actions: ', num2str(n_unique_actions)))

tuples = zeros(ntuples - 6, 3);
for ntuple = 6:ntuples - 1
    tuples(ntuple - 5, 1) = states(ntuple - 5);
    tuples(ntuple - 5, 2) = states(ntuple);
    tuples(ntuple - 5, 3) = actions(ntuple - 5);
end
ntuples = size(tuples, 1);

