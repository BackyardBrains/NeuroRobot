

% n = 2;
% agent = agents(n).agent;
% % reward_states = [5 13 14 17 25 28 29 32 35 38 40 41 43]; % bookshelf
% reward_states = [4 7 8 19 22 26 34 36 53]; % tv
% figure(n)

% clf
% set(gcf, 'color', 'w')
% set(gcf, 'position', [100 50 900 700])
% hold on

data = zeros(n_unique_states, 2);
motor_combs = zeros(n_unique_actions, 2);
for naction = 1:n_unique_actions
    y = naction * (n_unique_states/n_unique_actions);
    plot(4.5, y, 'marker', '.', 'markersize', 50, 'color', [0.8 0.8 0.8])
    motor_combs(naction, :) = round(mean(torque_data(actions == naction, :), 1));
    mvec = motor_combs(naction, :);    
    text(4.6, y, strcat(num2str(naction), '.  L: ', num2str(mvec(1)), ...
        ',  R: ', num2str(mvec(2))), 'HorizontalAlignment','left')    
end
for this_state = 1:n_unique_states
    this_action = getAction(agent, this_state);
    this_action = cell2mat(this_action);
    y = this_action * (n_unique_states/n_unique_actions);
    plot(2, this_state, 'marker', '.', 'markersize', 50, 'color', [0.2 0.4 0.8])
    plot(4.5, y, 'marker', '.', 'markersize', 50, 'color', [0.2 0.4 0.8])
    plot([2 4.5], [this_state y], 'linestyle', '-', 'marker', '.', 'markersize', 30, 'color', 'k', 'linewidth', 1);
    if sum(this_state == reward_states)
        if this_action == mode(actions)
            plot([2 4.5], [this_state y], 'linestyle', '-', 'marker', '.', 'markersize', 20, 'color', 'g', 'linewidth', 1);
        end
    end
    try
        text(1.9, this_state, horzcat(num2str(this_state), '. ', char(labels(this_state))), 'HorizontalAlignment','right')
    catch
    end
    drawnow
end
ylim([0 n_unique_states + 1])
xlim([1.5 5.5])
set(gca, 'ydir', 'reverse')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')

% title(horzcat(net_name, ' - ', agent_names{n}))
% set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
% export_fig(horzcat(workspace_dir_name, net_name, agent_names{n}), '-r150', '-jpg', '-nocrop')
