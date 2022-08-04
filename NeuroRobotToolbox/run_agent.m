
if use_controllers

    left_state = NaN;
    right_state = NaN;
    this_state = NaN;

    imdim = 100;
    left_uframe = imresize(left_uframe, [imdim imdim]);
    right_uframe = imresize(right_uframe, [imdim imdim]);

    [left_state, left_score] = classify(net, left_uframe);
    [right_state, right_score] = classify(net, right_uframe);

%     left_im.YData = left_score;
%     right_im.YData = right_score;

    left_state = find(unique_states == left_state);
    right_state = find(unique_states == right_state);

    left_score = left_score(left_state);
    right_score = right_score(right_state);

%     if max([left_score right_score]) > 0.75
        if left_state == right_state
            this_state = left_state;
        elseif left_score >= right_score
            this_state = left_state;
        else
            this_state = right_state;
        end
%     else
%         this_state = randsample(length(unique_states), 1);
%         disp('Confusion')
%     end
    disp('----')
    disp(horzcat('xstep: ', num2str(xstep)))
    disp(horzcat('left state: ', num2str(left_state), ', confidence: ', num2str(left_score)))
    disp(horzcat('right state: ', num2str(right_state), ', confidence: ', num2str(right_score)))
    disp(horzcat('state: ', num2str(this_state)))
    
    this_action = getAction(agent, this_state);

    this_motor_vector = motor_combs(cell2mat(this_action), :);
    this_motor_vector = this_motor_vector/2;

    disp(horzcat('action: ', num2str(cell2mat(this_action)), ', torques: ', num2str(round(this_motor_vector))))
    
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
