
if use_controllers

    imdim = 100;
    left_uframe = imresize(left_uframe, [imdim imdim]);
    right_uframe = imresize(right_uframe, [imdim imdim]);

    new_im = zeros(imdim, 178, 3, 'uint8');
    new_im(:, 1:imdim, :) = right_uframe;
    new_im(:, 79:178, :) = left_uframe;

    [state, scores] = classify(net, new_im);
    scores = scores(unique_states == state);
    this_state = find(unique_states == state);

    disp('----')
    disp(horzcat('xstep: ', num2str(xstep)))
    disp(horzcat('state: ', num2str(this_state), ' (', char(labels(this_state)), ')'))
    
    this_action = getAction(agent, this_state);
    this_action = cell2mat(this_action);

%     soundsc(state_wavs(this_state).wav, 16000);

    this_motor_vector = motor_combs(this_action, :);
    this_motor_vector = this_motor_vector/1;
%     this_motor_vector = [0 0];

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
    
end
