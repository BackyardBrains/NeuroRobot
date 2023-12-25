
state_net_name = ml_name1_edit.String;

if isempty(state_net_name)
    
    ml_name1_edit.BackgroundColor = [1 0.25 0.25];
    pause(0.75)
    ml_name1_edit.BackgroundColor = [0.94 0.94 0.94];

else

    ml_get_learn_speed
    
    axes(ml_load_status)
    cla
    txx = text(0.03, 0.5, 'Loading...');
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

    ml_visualize_mdp
    
    ml_get_combs_quick

    try
        load(horzcat(nets_dir_name, state_net_name, '-go2-', action_net_name, '-ml'))
        figure
        hold on
        scan_agent
        title(horzcat(state_net_name, '-', action_net_name))
        set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
    catch
    end
    
    txx.String = 'Ready to train decision network';

end

