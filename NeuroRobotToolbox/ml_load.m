
state_net_name = ml_name1_edit.String;

if isempty(state_net_name)
    
    ml_name1_edit.BackgroundColor = [1 0.25 0.25];
    pause(0.75)
    ml_name1_edit.BackgroundColor = [0.94 0.94 0.94];

else

    if ml_speed_select.Value == 1 % Slow
        learn_speed = 2;
    elseif ml_speed_select.Value == 2 % Medium
        learn_speed = 0.5;
    elseif ml_speed_select.Value == 3 % Fast
        learn_speed = 0.1;    
    end
    
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
    ntuples = size(states, 1);
    disp(horzcat('loaded ntuples: ', num2str(ntuples)))
    
    txx.String = 'Ready to train decision network';

end

