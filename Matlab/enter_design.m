if run_button == 1     
    design
    stop(runtime_pulse) % Why doesn't this cause an error
    clear data
    xstep = 1; % Does this produce a problem? 
    
    % Log command
    if save_data_and_commands
        this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
        command_log.entry(command_log.n).time = this_time;            
        command_log.entry(command_log.n).action = 'enter design';
        command_log.n = command_log.n + 1;
    end

end