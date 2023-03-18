
if record_data > 0

    if ~rem(xstep, 500)
        disp('Data recording is on')
        disp(horzcat('xstep:', num2str(xstep)))
    end
    
    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));

    % Save eye frames
    fname = strcat(dataset_dir_name, rec_dir_name, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-left_uframe.png');    
    imwrite(left_uframe, fname);
    fname = strcat(dataset_dir_name, rec_dir_name, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-right_uframe.png');
    imwrite(right_uframe, fname);    
    
    % Save torques
    torques = [left_torque_mem right_torque_mem];    
    fname = strcat(dataset_dir_name, rec_dir_name, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-torques.mat');
    save(fname, 'torques', '-mat')

    % Save serial input (incl. distance)
    if rak_only || use_esp32
        fname = strcat(dataset_dir_name, rec_dir_name, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-serial_data.mat');
        save(fname, 'serial_data', '-mat');
    end

    % Save audio input
%     if rak_only || use_esp32 || matlab_audio_rec
%         fname = strcat(dataset_dir_name, rec_dir_name, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-this_audio.mat');
%         save(fname, 'this_audio', '-mat');
%     end

    % Save external camera image
    if (rak_only || use_esp32) && use_webcam
        external_camera
        fname = strcat(dataset_dir_name, rec_dir_name, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-ext_data.mat');        
        save(fname, 'ext_data', '-mat');      
    end

end
