
load(strcat(nets_dir_name, net_name, '-net'))
load(strcat(nets_dir_name, net_name, '-labels'))
unique_states = unique(labels);
n_unique_states = length(unique_states);
load(horzcat(nets_dir_name, net_name, '-', rl_type, '-', agent_name, '-ml'))
load(strcat(nets_dir_name, net_name, '-torque_data'))
load(strcat(nets_dir_name, net_name, '-actions'))
% load(strcat(nets_dir_name, net_name, '-touch_states'))
n_unique_actions = length(unique(actions));
motor_combs = zeros(n_unique_actions, 2);
for naction = 1:n_unique_actions
    motor_combs(naction, :) = round(mean(torque_data(actions == naction, :), 1));
end
