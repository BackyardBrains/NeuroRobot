
if save_experiences > 0

    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));

    % State
    fname = strcat('.\Data\',this_time, '-', brain_name, '-', num2str(xstep), '-left_uframe.png');
    imwrite(left_uframe, fname);
    fname = strcat('.\Data\',this_time, '-', brain_name, '-', num2str(xstep), '-right_uframe.png');
    imwrite(left_uframe, fname);    
    
    % Action
    torques = [left_torque_mem right_torque_mem];    
    file_name = strcat('.\Data\', this_time, '-', brain_name, '-', num2str(xstep), '-torques.mat');
    save(file_name, 'rl_action', '-mat')

    % Non-state data
    if save_experiences && (rak_only || use_esp32)
        fname = strcat('.\Data\', this_time, '-', brain_name, '-', num2str(xstep), '-serial_data.mat');
        save(fname, 'serial_data', '-mat');
    end

    % Audio
%     if rak_only || use_esp32 || matlab_audio_rec
%         fname = strcat('.\Experiences\', this_time, '-', brain_name, '-', num2str(xstep), '-this_audio.mat');
%         save(fname, 'this_audio', '-mat');
%     end

end
