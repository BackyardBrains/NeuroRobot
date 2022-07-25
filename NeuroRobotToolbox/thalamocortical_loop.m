
if save_experiences > 0

    this_dir = '.\Data_3\Rec_1\';
    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));

    % State
    fname = strcat(this_dir, this_time, '-', brain_name, '-', num2str(xstep), '-left_uframe.png');
    imwrite(left_uframe, fname);
    fname = strcat(this_dir, this_time, '-', brain_name, '-', num2str(xstep), '-right_uframe.png');
    imwrite(right_uframe, fname);    
    
    % Action
    torques = [left_torque_mem right_torque_mem];    
    fname = strcat(this_dir, this_time, '-', brain_name, '-', num2str(xstep), '-torques.mat');
    save(fname, 'torques', '-mat')

    % Non-state data
    if rak_only || use_esp32
        fname = strcat(this_dir, this_time, '-', brain_name, '-', num2str(xstep), '-serial_data.mat');
        save(fname, 'serial_data', '-mat');
    end

    % Audio
%     if rak_only || use_esp32 || matlab_audio_rec
%         fname = strcat(this_dir, this_time, '-', brain_name, '-', num2str(xstep), '-this_audio.mat');
%         save(fname, 'this_audio', '-mat');
%     end

    % Tuples
    if use_controllers
        tuple = [this_state, cell2mat(this_action), left_state, left_score(left_state), right_state, right_score(right_state)];
        fname = strcat(this_dir, this_time, '-', brain_name, '-', num2str(xstep), '-tuple.mat');
        save(fname, 'tuple', '-mat');
    end

end
