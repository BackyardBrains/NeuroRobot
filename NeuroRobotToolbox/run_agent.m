
if use_controllers

    left_state = NaN;
    right_state = NaN;
    this_state = NaN;

    left_state = classify(net, left_uframe);
    right_state = classify(net, right_uframe);

    left_state = find(unique_states == left_state);
    right_state = find(unique_states == right_state);

    if left_state == right_state
        this_state = left_state;
    else
        this_state = right_state;
    end   

    disp(horzcat('state: ', num2str(this_state)))
    
    this_action = getAction(agent, this_state);

    this_motor_vector = motor_combs(this_action, :);

    disp(horzcat('action: ', num2str(cell2mat(this_action)), ', torques: ', num2str(this_motor_vector)))
    
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


%     this_motor_vector = motor_combs(cell2mat(this_action), :);
%     this_motor_vector = this_motor_vector/2;
    
%     disp(horzcat('action: ', num2str(cell2mat(this_action)), ', torques: ', num2str(this_motor_vector(2:3))))
%     
%     if this_motor_vector(2) > 0
%         left_forward = this_motor_vector(2);
%     else
%         left_backward = -this_motor_vector(2);
%     end
%     
%     if this_motor_vector(3) > 0
%         right_forward = this_motor_vector(3);
%     else
%         right_backward = -this_motor_vector(3);
%     end



end
