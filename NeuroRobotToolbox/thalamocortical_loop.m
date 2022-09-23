
% xstep
if save_experiences > 0

    disp(horzcat('xstep:', num2str(xstep)))

    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));

    % State
    fname = strcat(data_dir_name, rec_dir_name, '-', computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-left_uframe.png');
    imwrite(left_uframe, fname);
    fname = strcat(data_dir_name, rec_dir_name, '-', computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-right_uframe.png');
    imwrite(right_uframe, fname);    
    
    % Action
    torques = [left_torque_mem right_torque_mem];    
    fname = strcat(data_dir_name, rec_dir_name, '-', computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-torques.mat');
    save(fname, 'torques', '-mat')

    % Non-MDP data
    if rak_only || use_esp32
        fname = strcat(data_dir_name, rec_dir_name, '-', computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-serial_data.mat');
        save(fname, 'serial_data', '-mat');
    end

    % Audio
%     if rak_only || use_esp32 || matlab_audio_rec
%         fname = strcat(data_dir_name, rec_dir_name, '-', computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-this_audio.mat');
%         save(fname, 'this_audio', '-mat');
%     end

end
