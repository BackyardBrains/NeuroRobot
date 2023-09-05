
if nneurons
    
    if run_button == 5
        
        % Command log
        if save_data_and_commands
            this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
            command_log.entry(command_log.n).time = this_time;
            command_log.entry(command_log.n).action = 'enter reward';
            command_log.n = command_log.n + 1;
        end
        
        % Display and update
        disp(horzcat('Dopamine reward :)'))
        run_button = 0;
        reward = 1;
        
    end
    
    if sum(da_rew_neurons(firing))
        reward = 1;
    end
    
    if reward
        set(button_reward, 'BackgroundColor', [0.8 1 0.8]);
    else
        set(button_reward, 'BackgroundColor', [0.8 0.8 0.8]);
    end

end
