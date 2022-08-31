if rak_only || use_esp32
    if script_running == 1
        just_red
    elseif script_running == 2
        just_green
    elseif script_running == 3
        just_blue
    elseif script_running == 4
        just_off
    elseif sum(script_running == 5:10)
        run_agent    
    else
        disp('Unknown behavior')
    end
end
script_running = 0;