
set(gcf, 'position', [100 50 1280 720])
data = zeros(nstates, 2);
clf
hold on
for this_state = 1:nstates
    this_action = getAction(agent, this_state);
    this_action = cell2mat(this_action);
    plot([1 2], [this_state this_action * round(nstates/nactions)], 'linestyle', '-', 'marker', '.', 'markersize', 10, 'color', 'k', 'linewidth', 1);
    drawnow
end

