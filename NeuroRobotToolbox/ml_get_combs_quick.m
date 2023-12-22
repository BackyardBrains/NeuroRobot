
n_unique_actions = length(unique(actions));
motor_combs = zeros(n_unique_actions, 2);

for naction = 1:n_unique_actions
    motor_combs(naction, :) = mean(torque_data(actions == naction, :));
end