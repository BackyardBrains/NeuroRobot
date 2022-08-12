
% n_unique_states  = 25;
% n_unique_actions = 4;

set(gcf, 'position', [100 50 960 540])
data = zeros(n_unique_states, 2);
clf
hold on
for this_state = 1:n_unique_states
    this_action = getAction(agent, this_state);
    this_action = cell2mat(this_action);
    plot([1 2], [this_state this_action * (n_unique_states/n_unique_actions)], 'linestyle', '-', 'marker', '.', 'markersize', 30, 'color', 'k', 'linewidth', 1);
    if sum(this_state == reward_states)
        plot([1 2], [this_state this_action * (n_unique_states/n_unique_actions)], 'linestyle', '-', 'marker', '.', 'markersize', 20, 'color', 'g', 'linewidth', 1);
    end
    drawnow
end

