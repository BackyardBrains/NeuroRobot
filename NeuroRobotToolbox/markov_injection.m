

% markov injection (assumes you already ran neurorobot.m)

net_name = 'livingroom'
tv = [4 8 16 18 19 32 40 48]

load(horzcat(nets_dir_name, net_name, '-states'))
load(horzcat(nets_dir_name, net_name, '-torque_data'))
ntuples = size(torque_data, 1);
disp(horzcat('ntuples: ', num2str(ntuples)))

load(strcat(nets_dir_name, net_name, '-net'))
load(strcat(nets_dir_name, net_name, '-labels'))
n_unique_states = length(labels);
disp(horzcat('n unique states: ', num2str(n_unique_states)))

load(strcat(nets_dir_name, net_name, '-actions'))
n_unique_actions = length(unique(actions));
disp(horzcat('n unique actions: ', num2str(n_unique_actions)))

tuples = zeros(ntuples - 6, 3);
for ntuple = 6:ntuples - 1
    tuples(ntuple - 5, 1) = states(ntuple - 5);
    tuples(ntuple - 5, 2) = states(ntuple);
    tuples(ntuple - 5, 3) = actions(ntuple - 5);
end
ntuples = size(tuples, 1);

