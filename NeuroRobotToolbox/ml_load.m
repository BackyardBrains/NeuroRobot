
this_net_name = ml_name1_edit.String;
this_ind = strfind(this_net_name, '---');
if ~isempty(this_ind)
    state_net_name = this_net_name(1:this_ind - 1);
    action_net_name = this_net_name(this_ind + 3:end);
else
    state_net_name = this_net_name;
end

try    
    axes(ml_load_status)
    cla
    txx = text(0.03, 0.5, 'Loading...', 'fontsize', bfsize + 4);
    drawnow
    
    try
    openfig(strcat(nets_dir_name, state_net_name, '-examples.fig'));
    catch
    end
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
    
    txx.String = 'Ready to train decision network';

catch

    ml_name1_edit.BackgroundColor = [1 0.25 0.25];
    pause(0.75)
    ml_name1_edit.BackgroundColor = [0.94 0.94 0.94];

end

