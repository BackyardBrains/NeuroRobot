
state_net_name = ml_name1_edit.String;

if isempty(state_net_name)
    
    ml_name1_edit.BackgroundColor = [1 0.25 0.25];
    pause(0.75)
    ml_name1_edit.BackgroundColor = [0.94 0.94 0.94];

else

    ml_get_learn_speed
    
    axes(ml_load_status)
    cla
    txx = text(0.03, 0.5, 'Loading...', 'fontsize', bfsize + 4);
    drawnow
    
    openfig(strcat(nets_dir_name, state_net_name, '-examples.fig'))
    load(strcat(nets_dir_name, state_net_name, '-states'))
    load(strcat(nets_dir_name, state_net_name, '-torque_data'))
    load(strcat(nets_dir_name, state_net_name, '-actions'))
    load(strcat(nets_dir_name, state_net_name, '-tuples'))
    load(strcat(nets_dir_name, state_net_name, '-mdp'))
    n_unique_states = length(unique(states));
    n_unique_actions = length(unique(actions));
    ntuples = size(torque_data, 1);
    disp(horzcat('loaded ntuples: ', num2str(ntuples)))

    % ml_visualize_mdp
    
    ml_get_combs_quick
    
    figure(9)
    clf
    gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*4, torque_data(:,2)+randn(size(torque_data(:,2)))*4, actions, [],[],[], 'off')
    hold on
    for naction = 1:n_unique_actions
        text(motor_combs(naction,1), motor_combs(naction,2), num2str(naction), 'fontsize', 16, 'fontweight', 'bold')
    end
    axis padded
    set(gca, 'yscale', 'linear')
    title('Actions')
    xlabel('Torque 1')
    ylabel('Torque 2')
    drawnow

    try
        load(horzcat(nets_dir_name, state_net_name, '-go2-', action_net_name, '-ml'))
        figure
        hold on
        scan_agent
        title(horzcat(state_net_name, '-', action_net_name))
        set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
        drawnow
    catch
    end
    
    txx.String = 'Ready to train decision network';

end

