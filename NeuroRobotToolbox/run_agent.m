
if use_controllers
    
    xxxx = predict(net, uframe)
    
    disp(horzcat('state: ', num2str(this_state)))
    
    this_action = getAction(agent, this_state);
    
    disp(horzcat('action: ', num2str(cell2mat(this_action))))
    
    this_motor_vector = motor_combs(cell2mat(this_action), :);
    
%     this_motor_vector = this_motor_vector / 2;
    
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
