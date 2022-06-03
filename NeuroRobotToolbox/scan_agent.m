

data = zeros(1024, 2);
clf
hold on
for this_state = 1:1024
    this_action = getAction(agent, this_state);
    this_action = cell2mat(this_action);
    plot([1 2], [this_state this_action * 40], 'linestyle', '-', 'marker', '.', 'markersize', 10, 'color', 'k', 'linewidth', 1);
    drawnow
end

