
% xstep
if save_experiences > 0

    disp(horzcat('xstep:', num2str(xstep)))

    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));

    % State
%     fname = strcat(data_dir_name, rec_dir_name, '-', computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-left_uframe.png');    
    fname = strcat(rec_dir_name_2, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-left_uframe.png');
    imwrite(left_uframe, fname);
%     fname = strcat(data_dir_name, rec_dir_name, '-', computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-right_uframe.png');
    fname = strcat(rec_dir_name_2, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-right_uframe.png');

    imwrite(right_uframe, fname);    
    
    % Action
    torques = [left_torque_mem right_torque_mem];    
%     fname = strcat(data_dir_name, rec_dir_name, '-', computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-torques.mat');
    fname = strcat(rec_dir_name_2, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-torques.mat');    
    save(fname, 'torques', '-mat')

    % Non-MDP data
    if rak_only || use_esp32
%         fname = strcat(data_dir_name, rec_dir_name, '-', computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-serial_data.mat');
        fname = strcat(rec_dir_name_2, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-serial_data.mat');
        save(fname, 'serial_data', '-mat');
    end

    % Audio
%     if rak_only || use_esp32 || matlab_audio_rec
%         fname = strcat(data_dir_name, rec_dir_name, '-', computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-this_audio.mat');
%         save(fname, 'this_audio', '-mat');
%     end

    % External webcam mode
    if (rak_only || use_esp32) && use_webcam

        trigger(ext_cam)
        ext_frame = getdata(ext_cam, 1); %%% <<<<< Commented out for packaging        
        ext_uframe = imresize(ext_frame, [227 404]);
        ext_im.CData = ext_uframe;
        disp('33')

%         ext_xframe = imsubtract(rgb2gray(ext_uframe), rgb2gray(prev_ext_uframe));
%         ext_bwframe = ext_xframe > 2;  
%         ext_blob = bwconncomp(ext_bwframe);
%         if ext_blob.NumObjects
%             [npx, this_blob] = max(cellfun(@numel,ext_blob.PixelIdxList));
%             [y, x] = ind2sub(ext_blob.ImageSize, ext_blob.PixelIdxList{this_blob});
%             robot_xy = [mean(x), mean(y)];
%         else
%             robot_xy = [0 0];
%         end
%         prev_ext_uframe = ext_uframe;
%         
% %         fname = strcat(data_dir_name, rec_dir_name, '-', computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-robot_xy.mat');
%         fname = strcat(rec_dir_name_2, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-robot_xy.mat');        
%         save(fname, 'robot_xy', '-mat');
%         disp(horzcat('x = ', num2str(robot_xy(1)), ', y = ', num2str(robot_xy(2))))
    end    

end
