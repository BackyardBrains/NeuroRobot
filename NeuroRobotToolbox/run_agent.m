
if use_controllers

    left_state = NaN;
    right_state = NaN;
    this_state = NaN;

    imdim = 227;
    left_uframe = imresize(left_uframe, [imdim imdim]);
    right_uframe = imresize(right_uframe, [imdim imdim]);

    new_im = zeros(227, 404, 3, 'uint8');    
    new_im(:, 1:227, :) = right_uframe;
    new_im(:, 178:404, :) = left_uframe;

    [state, scores] = classify(net, new_im);
    scores = scores(unique_states == state);
    this_state = find(unique_states == state);

%     [left_state, left_score] = classify(net, left_uframe);
%     [right_state, right_score] = classify(net, right_uframe);

%     left_im.YData = left_score;
%     right_im.YData = right_score;

%     left_state = find(unique_states == left_state);
%     right_state = find(unique_states == right_state);

%     left_score = left_score(left_state);
%     right_score = right_score(right_state);
% 
%     if left_state == right_state
%         this_state = left_state;
%     elseif left_score >= right_score
%         this_state = left_state;
%     else
%         this_state = right_state;
%     end

    disp('----')
    disp(horzcat('xstep: ', num2str(xstep)))
%     disp(horzcat('left state: ', num2str(left_state), ' (', char(labels(left_state)), '), confidence: ', num2str(left_score)))
%     disp(horzcat('right state: ', num2str(right_state), ' (', char(labels(right_state)), '), confidence: ', num2str(right_score)))
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
