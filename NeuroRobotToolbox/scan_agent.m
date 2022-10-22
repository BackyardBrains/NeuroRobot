figure(12)
clf
set(gcf, 'color', 'w')

% n_unique_states  = 25;
% n_unique_actions = 4;

set(gcf, 'position', [100 50 960 540])
data = zeros(n_unique_states, 2);
clf
hold on
for this_state = 1:n_unique_states
    this_action = getAction(agent, this_state);
    this_action = cell2mat(this_action);
    plot([1 1], [this_state this_state], 'marker', '.', 'markersize', 50, 'color', [0.2 0.4 0.8])
    plot([2 2], [this_action this_action] * (n_unique_states/n_unique_actions), 'marker', '.', 'markersize', 50, 'color', [0.2 0.4 0.8])
    plot([1 2], [this_state this_action * (n_unique_states/n_unique_actions)], 'linestyle', '-', 'marker', '.', 'markersize', 30, 'color', 'k', 'linewidth', 1);
    if sum(this_state == reward_states)
        if this_action == mode(actions)
            plot([1 2], [this_state this_action * (n_unique_states/n_unique_actions)], 'linestyle', '-', 'marker', '.', 'markersize', 20, 'color', 'g', 'linewidth', 1);
        end
    end
    mvec = motor_combs(this_action, :);
    text(0.5, this_state, char(labels(this_state)))
    text(1.5, this_action * (n_unique_states/n_unique_actions), strcat('A:', num2str(this_action), ...
        'L:', num2str(mvec(this_action, 1), 'R:', num2str(mvec(this_action, 2)))))
    drawnow
end
ylim([0 n_unique_states + 1])
xlim([0 3])

set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')