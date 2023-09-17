
if use_custom_net

    % Get single state 
    % (expecting state net output 
    % from process_visual_input.m)

    if use_cnn
        [left_score, left_state] = max(vis_pref_vals(8+13:n_vis_prefs, 1));
        [right_score, right_state] = max(vis_pref_vals(8+13:n_vis_prefs, 2));
    else
        [left_score, left_state] = max(vis_pref_vals(8:n_vis_prefs, 1));
        [right_score, right_state] = max(vis_pref_vals(8:n_vis_prefs, 2));
    end

    if ~isempty(left_score) && ~isempty(right_score)
        if left_state == right_state
            this_state = left_state;
        elseif left_score >= right_score
            this_state = left_state;
        else
            this_state = right_state;
        end
    else
        this_state = nan;
        disp('state detection error')
    end
    
%     if sum(this_state == touch_states) && this_distance > 0 && this_distance ~= 4000
%         ind = find(this_state == touch_states);
%         this_state = n_unique_states + ind;
%     end

    disp('')
    disp(horzcat('xstep: ', num2str(xstep)))
    disp(horzcat('state: ', num2str(this_state)))
    disp(horzcat('score: ', num2str(max([left_score right_score]))))
    disp(horzcat('dist: ', num2str(this_distance)))
    disp('')
   
    if length(cnet_temp) >= 2
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
            left_backward = -this_motor_vector(1);
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
