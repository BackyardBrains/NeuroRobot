
if record_data > 0

    if ~rem(xstep, 500)
        disp('Data recording is on')
        disp(horzcat('xstep:', num2str(xstep)))
    end
    
    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));

    % Save image
    fname = strcat(dataset_dir_name, rec_dir_name, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-large_frame_x.png');    
    imwrite(large_frame, fname);
    
    % Save torques
    torques = [left_torque_mem right_torque_mem];    
    fname = strcat(dataset_dir_name, rec_dir_name, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-torques.mat');
    save(fname, 'torques', '-mat')

    % Save serial input
    fname = strcat(dataset_dir_name, rec_dir_name, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-serial_data.mat');
    if rak_only || use_esp32
        save(fname, 'serial_data', '-mat');
    else
        serial_data = [0 0];
        save(fname, 'serial_data', '-mat');
    end

%     % Save audio input
%     if rak_only || use_esp32 || matlab_audio_rec
%         fname = strcat(dataset_dir_name, rec_dir_name, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-this_audio.mat');
%         save(fname, 'this_audio', '-mat');
%     end

    % Save brain state
    fname = strcat(dataset_dir_name, rec_dir_name, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-spikes_step.mat');
    save(fname, 'spikes_step', '-mat');

    % Save external camera image
    if use_esp32 && use_webcam
        external_camera
        fname = strcat(dataset_dir_name, rec_dir_name, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-ext_data.mat');        
        save(fname, 'ext_data', '-mat');      
    end

end
