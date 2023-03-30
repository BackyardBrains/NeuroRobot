
if use_controllers

    % Get single state (expecting state net output from
    % process_visual_input.m)
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
%     disp(horzcat('ai flag: ', num2str(ai_flag)))
    disp(horzcat('state: ', num2str(this_state), ' (', char(labels(this_state)), ')'))
    
%     this_action = getAction(agents(ai_flag).agent, this_state);
    this_action = getAction(agent, this_state);
    this_action = cell2mat(this_action);


%     if this_action == 10
%         ai_count = ai_count + 1;
%         if ai_count >= 20
%             ai_count = 0;
%             while ai_count == 0
%                 new_flag = randsample(nagents, 1);
%                 if new_flag ~= ai_flag
%                     ai_flag = new_flag;
%                     ai_count = ai_count + 1;
%                 end
%                 just_off
%                 pause(0.02)
%                 just_off
%                 pause(0.02)
%                 just_off
%                 pause(0.02)
%                 just_off
%                 pause(0.02)
%                 just_off
%                 pause(0.02)
%                 just_off
%                 pause(0.02)
%                 just_off                
%             end
%         end
%     else    
%         ai_count = 0;
%         if ai_flag == 1
%             just_green
%         elseif ai_flag == 2
%             just_red
%         end
% 
%     end

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
