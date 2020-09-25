

% Search

script_step_count = script_step_count + 1;

% At the start
if script_step_count == 1
    % Get strong current visual inputs
    sensory_in_trig = vis_pref_vals > 42;
    % If this fails, quit
    if ~sum(sensory_in_trig(:))
        script_running = 0;
        script_step_count = 0;
    end
    
        rak_cam.writeSerial('d:120;')   
        pause(0.05)
        rak_cam.writeSerial('d:220;')
        pause(0.05)
        rak_cam.writeSerial('d:320;')   
        pause(0.05)
        rak_cam.writeSerial('d:420;')
        pause(0.05)
        rak_cam.writeSerial('d:520;')   
        pause(0.05)
        rak_cam.writeSerial('d:620;')
        pause(0.05)        
    isfound = 0;
end

% Turn around
if script_step_count <= 8
    left_forward = left_forward + 50;
    right_backward = right_backward + 50;      
% Then
elseif script_step_count <= 10
    left_forward = left_forward + 20;
    right_forward = right_forward + 20;    
else
    % If none of the strong visual stimuli are currently present
    if ~sum(sensory_in_trig(vis_pref_vals > 42)) && ~isfound
        % Move randomly forward
        left_forward = left_forward + rand * 50;
        right_forward = right_forward + rand * 50;        
    else
    % Otherwise, quit (target found)
        if size(sensory_in_trig(vis_pref_vals > 42), 2) > 1
            error('Array needs to be (:)d before ln 25')
        end
        
        if ~isfound
            rak_cam.writeSerial('d:121;')   
            pause(0.05)
            rak_cam.writeSerial('d:221;')
            pause(0.05)
            rak_cam.writeSerial('d:321;')   
            pause(0.05)
            rak_cam.writeSerial('d:421;')
            pause(0.05)
            rak_cam.writeSerial('d:521;')   
            pause(0.05)
            rak_cam.writeSerial('d:621;')
            pause(0.05)  
        end
        isfound = 1;
    end
end
% Give up the search after 10 seconds
if (script_step_count * pulse_period) > 5
    
    rak_cam.writeSerial('d:120;')   
    pause(0.05)
    rak_cam.writeSerial('d:220;')
    pause(0.05)
    rak_cam.writeSerial('d:320;')   
    pause(0.05)
    rak_cam.writeSerial('d:420;')
    pause(0.05)
    rak_cam.writeSerial('d:520;')   
    pause(0.05)
    rak_cam.writeSerial('d:620;')
    pause(0.05)   

    script_running = 0;
    script_step_count = 0;  
    isfound = 0;
end