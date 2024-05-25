
for naction = 1:n_unique_actions
    y = naction * (n_unique_states/n_unique_actions);
    plot(4, y, 'marker', '.', 'markersize', 50, 'color', [0.8 0.8 0.8])
    mvec = motor_combs(naction, :);    
    text(4.2, y, strcat('action: ', num2str(naction), '.  L: ', num2str(mvec(1)), ',  R: ', num2str(mvec(2))), 'HorizontalAlignment','left')    
end
for this_state = 1:n_unique_states
    this_action = getAction(agent, this_state);
    this_action = cell2mat(this_action);
    y = this_action * (n_unique_states/n_unique_actions);
    plot(2.5, this_state, 'marker', '.', 'markersize', 50, 'color', [0.2 0.4 0.8])
    plot(4, y, 'marker', '.', 'markersize', 50, 'color', [0.2 0.4 0.8])
    plot([2.5 4], [this_state y], 'linestyle', '-', 'marker', '.', 'markersize', 30, 'color', 'k', 'linewidth', 1);
    if sum(this_state == reward_states)
        if this_action == reward_action
            plot([2.5 4], [this_state y], 'linestyle', '-', 'marker', '.', 'markersize', 20, 'color', 'g', 'linewidth', 1);
        end
    end
    try
        text(2.3, this_state, horzcat('state: ', num2str(this_state)), 'HorizontalAlignment','right')
    catch
    end
    drawnow
end
ylim([0 n_unique_states + 1])
xlim([1.5 5.5])
set(gca, 'ydir', 'reverse')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')

