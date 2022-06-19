

% This is all the data saved in Experiences for later hippocampal and basal
% ganglia processing

% Try: Have robot spin round a KNOWN number of times. Label manually and
% compare to autonomous (unsupervised) learning

% special_tic = tic;

if save_experiences > 0

    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));  
        
    rl_tuple = {rl_left_torque, rl_right_torque};
    file_name = strcat('.\Experiences\', this_time, '-', brain_name, '-', num2str(xstep), '-tuple.mat');
    save(file_name, 'rl_tuple', '-mat')
    rl_state = rl_next_state;
    rl_action = [left_torque_mem right_torque_mem]; % this_network? % this will need binarization later
    
    rl_reward = reward; % should this be from the next time step? does it matter?
    
    % toc(special_tic)

end

if save_experiences == 2

    if camera_present
        fname = strcat('.\Experiences\',this_time, '-', brain_name, '-', num2str(xstep), '-left_uframe.png');
        imwrite(left_uframe, fname);
        fname = strcat('.\Experiences\', this_time, '-', brain_name, '-', num2str(xstep), '-right_uframe.png');
        imwrite(right_uframe, fname);
    end

    if rak_only || use_esp32 || matlab_audio_rec
        fname = strcat('.\Experiences\', this_time, '-', brain_name, '-', num2str(xstep), '-this_audio.mat');
        save(fname, 'this_audio', '-mat');
    end

end

if save_experiences && (rak_only || use_esp32)
    fname = strcat('.\Experiences\', this_time, '-', brain_name, '-', num2str(xstep), '-serial_data.mat');
    save(fname, 'serial_data', '-mat');
end

