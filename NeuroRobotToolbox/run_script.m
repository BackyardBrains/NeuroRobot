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
    if script_running == 5
        this_agent = 1;
    elseif script_running == 6
        this_agent = 2;
    end

    run_agent   
    
else
    disp('Unknown behavior')
end
script_running = 0;