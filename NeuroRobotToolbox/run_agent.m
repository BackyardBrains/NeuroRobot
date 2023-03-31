
if use_controllers

    % Get single state 
    % (expecting state net output 
    % from process_visual_input.m)

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

    disp('')
    disp(horzcat('xstep: ', num2str(xstep)))
    disp(horzcat('state: ', num2str(this_state), ' (', char(labels(this_state)), ')'))

    % Get action
    this_action = getAction(agent, this_state);
    this_action = cell2mat(this_action);
    this_motor_vector = motor_combs(this_action, :);
    disp(horzcat('action: ', num2str(this_action), ', torques: ', num2str(round(this_motor_vector))))
    
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
    
else

    disp('')
    disp(horzcat('xstep: ', num2str(xstep)))    
    disp('RL agent not loaded: skipping ...')

end
