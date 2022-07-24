
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
        tuples(xstep, 1) = this_state;
        tuples(xstep, 2) = cell2mat(this_action);
        tuples(xstep, 3) = left_state;
        tuples(xstep, 4) = left_score(left_state);
        tuples(xstep, 5) = right_state;
        tuples(xstep, 6) = right_score(right_state);
        fname = strcat(this_dir, this_time, '-', brain_name, '-', num2str(xstep), '-tuples.mat');
        save(fname, 'tuples', '-mat');
    end

end
