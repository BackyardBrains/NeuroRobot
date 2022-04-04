if run_button == 1     
    design
%     rak_cam.stop();
    stop(runtime_pulse) % Why doesn't this cause an error
    
    if rak_only || use_esp32 || use_webcam
        if exist('rak_pulse', 'var') && isvalid(rak_pulse)
            stop(rak_pulse)
            delete(rak_pulse)
        end
        rak_pulse = timer('period', pulse_period, 'timerfcn', 'rak_pulse_code', 'executionmode', 'fixedrate');    
        start(rak_pulse)     
    end
    
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