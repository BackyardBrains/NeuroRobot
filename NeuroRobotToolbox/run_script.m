
if rak_only || use_esp32
    if script_running == 1
        just_red
    elseif script_running == 2
        just_green
    elseif script_running == 3
        just_blue
    elseif script_running == 4
        just_off
    end
end

if sum(script_running == 1:4)
elseif sum(script_running == 5:6)
    if script_running == 5 % Agent
        this_agent = 1;
        run_agent
    elseif script_running == 6 % Compass
        
        left_forward = 0;
        left_backward = 0;
        right_forward = 0;
        right_backward = 0;

        this_val = double(scores) - 180;

        left_forward = this_val;
        right_backward = this_val;
        disp(horzcat('Theta = ', num2str(this_val), ...
            ', left = ', num2str(left_forward), ...
            ', right = ', num2str(right_backward)))

    end    
else
    disp('Unknown behavior')
end
script_running = 0;
