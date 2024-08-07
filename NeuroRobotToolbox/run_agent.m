
if use_custom_net

    % Get single state 
    % (expecting state net output 
    % from process_visual_input.m)

    if use_cnn
        [this_score, this_state] = max(vis_pref_vals(8+13:n_vis_prefs, 1));
    else
        [this_score, this_state] = max(vis_pref_vals(8:n_vis_prefs, 1));
    end

    disp('')
    disp(horzcat('xstep: ', num2str(xstep)))
    disp(horzcat('state: ', num2str(this_state)))
    disp(horzcat('score: ', num2str(this_score)))
    try
        disp(horzcat('dist: ', num2str(this_distance)))
    catch
    end
    disp('')
   
    if length(cnet_temp) >= 1

        % Get action
        this_action = getAction(agent, this_state);
        this_action = cell2mat(this_action);
        this_motor_vector = motor_combs(this_action, :);
        disp(horzcat('action: ', num2str(this_action), ', torques: ', num2str(this_motor_vector)))
        
        left_forward = 0;
        left_backward = 0;
        right_forward = 0;
        right_backward = 0;
    
        if this_motor_vector(1) > 0
            left_forward = this_motor_vector(1);
        else
            left_backward = this_motor_vector(1);
        end
        
        if this_motor_vector(2) > 0
            right_forward = this_motor_vector(2);
        else
            right_backward = -this_motor_vector(2);
        end
    end


else

    disp('')
    disp(horzcat('xstep: ', num2str(xstep)))    
    disp('RL agent not loaded: skipping ...')

end
