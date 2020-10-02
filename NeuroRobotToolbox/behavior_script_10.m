

% Find it
% Strategy E
% Finds another instance of the visual stimulus it is currently observing

script_step_count = script_step_count + 1;

if script_step_count == 1 % The first time script is executed
    sensory_in_trig = vis_pref_vals > 20; % Get strong current visual inputs
    if ~sum(sensory_in_trig(:)) % If this fails, quit
        script_running = 0;
        script_step_count = 0;
        disp('Failed to start')
    end
    spinled = 0; % Variable to use for counting
end

if script_running
    if script_step_count <= 10 % During the first second
        left_forward = left_forward + 40; % Spin around
        right_backward = right_backward + 40;      
    elseif script_step_count <= 20 % During the second second
        left_forward = left_forward + 40; % Move forward
        right_forward = right_forward + 40;    
    else % From then on
        if ~sum(sensory_in_trig(vis_pref_vals > 20)) % If visual targets are currently absent

            % Execute a search
            lights_out
            if ~rem(script_step_count, 20)
                spinled = 10;
            end
            if ~rem(script_step_count, 25)
                spinled = -10;
            end
            if spinled > 0
                left_forward = left_forward + 50;
                right_backwawrd = right_backward + 50;
                spinled = spinled - 1;
            end
            if spinled < 0
                left_forward = left_forward + 50;
                right_forward = right_forward + 50;
                spinled = spinled + 1;
            end

        else % Otherwise

            reward = 1; % Enjoy
            rak_cam.writeSerial('d:121;d:221;d:321;d:421;d:521;d:621;') % Party

        end
    end

    % End script after 10 seconds
    if (script_step_count * pulse_period) > 10
        lights_out    
        script_running = 0;
        script_step_count = 0;
    end
end
