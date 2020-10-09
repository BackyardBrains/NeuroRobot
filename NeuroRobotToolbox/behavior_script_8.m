

% Find C

script_step_count = script_step_count + 1;

% At the start
if script_running
if script_step_count == 1
    % Get strong current visual inputs
    sensory_in_trig = vis_pref_vals > 20;
    % If this fails, quit
    if ~sum(sensory_in_trig(:))
        script_running = 0;
        script_step_count = 0;
        disp('Failed to start')
    else
        lights_out    
    end
    isfound = 0;
    spinled = 0;
end

% Turn around
if script_step_count <= 10
    left_forward = left_forward + 50;
    right_backward = right_backward + 50;      
% Then
elseif script_step_count <= 20
    left_forward = left_forward + 20;
    right_forward = right_forward + 20;    
else
    % If none of the strong visual stimuli are currently present
    if ~sum(sensory_in_trig(vis_pref_vals > 20)) && ~isfound
        if ~rem(script_step_count, 20)
            spinled = round(rand * 100);
        end

        left_forward = left_forward + spinled;
        right_forward = right_forward + spinled;
    else
    % Otherwise, quit (target found)
        disp('Found')
        if size(sensory_in_trig(vis_pref_vals > 20), 2) > 1
            error('Array needs to be (:)d before ln 25')
        end
        
        if ~isfound
            rak_cam.writeSerial('d:121;d:221;d:321;d:421;d:521;d:621;')
        end
        isfound = 1;
    end
end
% Give up the search after 10 seconds
if (script_step_count * pulse_period) > 10

    lights_out
    
    if ~isfound
        rak_cam.writeSerial('d:131;d:231;d:331;d:431;d:531;d:631;')
    end
    script_running = 0;
    script_step_count = 0;  
    isfound = 0;
    
    disp('Giving up')
end
end
if isfound
    reward = 1;
end
