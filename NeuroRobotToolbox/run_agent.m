
if use_controllers

    imdim = 100;
    left_uframe = imresize(left_uframe, [imdim imdim]);
    right_uframe = imresize(right_uframe, [imdim imdim]);

    left_state = NaN;
    right_state = NaN;
    this_state = NaN;

    [left_state, left_score] = classify(net, left_uframe);
    [right_state, right_score] = classify(net, right_uframe);        

    left_state = find(unique_states == left_state);
    right_state = find(unique_states == right_state);

    left_score = left_score(left_state);
    right_score = right_score(right_state);

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

    disp('----')
    disp(horzcat('xstep: ', num2str(xstep)))
    disp(horzcat('state: ', num2str(this_state), ' (', char(labels(this_state)), ')'))
    
    this_action = getAction(agents(this_agent).agent, this_state);
    this_action = cell2mat(this_action);

%     if this_action == 10
%         just_green
%     else
%         just_off
%     end
    if this_agent == 1
        send_this = 'd:131;d:231;d:331;d:431;d:531;d:631;d:120;d:220;d:320;d:420;d:520;d:620;';
        if rak_only
            rak_cam.writeSerial(send_this)
        elseif use_esp32
            esp32WebsocketClient.send(send_this);
        end
    elseif this_agent == 2
        send_this = 'd:121;d:221;d:321;d:421;d:521;d:621;d:130;d:230;d:330;d:430;d:530;d:630;';
        if rak_only
            rak_cam.writeSerial(send_this)
        elseif use_esp32
            esp32WebsocketClient.send(send_this);
        end
    end

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
