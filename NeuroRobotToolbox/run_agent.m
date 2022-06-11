
if use_controllers
    
    [left_featureVector, words] = encode(bag, left_uframe, 'UseParallel', 0);
    locs = words.Location;
    clear left_featureVector_locs
    for nfeature = 1:5
        left_featureVector_locs(nfeature) = mean(locs(words.WordIndex == nfeature, 2)) / 227;
    end
    
    [right_featureVector, words] = encode(bag, right_uframe, 'UseParallel', 0);
    locs = words.Location;
    clear right_featureVector_locs
    for nfeature = 1:5
        right_featureVector_locs(nfeature) = mean(locs(words.WordIndex == nfeature, 2)) / 227;
    end
    
    % state_vector = [left_featureVector left_featureVector_locs right_featureVector right_featureVector_locs];
    state_vector = [left_featureVector right_featureVector];
    
    state_vector = padarray(state_vector, [0 1], 0, 'pre');
    state_vector = padarray(state_vector, [0 1], 1, 'post');  % Change 1 to 50 to do raw state
    
    r = corr(state_vector', state_combs');
    [~, this_state] = max(r);
    
    disp(horzcat('state: ', num2str(this_state)))
    
    this_action = getAction(agent, this_state);
    
    disp(horzcat('action: ', num2str(cell2mat(this_action))))
    
    this_motor_vector = motor_combs(cell2mat(this_action), :);
    
    this_motor_vector = this_motor_vector / 2;
    
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
