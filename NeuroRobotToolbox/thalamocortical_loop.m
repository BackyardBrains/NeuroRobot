

% This is all the data saved in Experiences for later hippocampal and basal
% ganglia processing

% Try: Have robot spin round a KNOWN number of times. Label manually and
% compare to autonomous (unsupervised) learning

% special_tic = tic;

if save_experiences > 0

    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));  
    
    if raw_or_bag == 1    
        left_featureVector = vis_pref_vals([1 4 7 10],1);
        right_featureVector = vis_pref_vals([1 4 7 10],2);
        rl_next_state = [left_featureVector' right_featureVector'];
    elseif raw_or_bag == 2 || use_controllers
        [left_featureVector, words] = encode(bag, left_uframe, 'UseParallel', 0);
        locs = words.Location;
        clear left_featureVector_locs
        for nfeature = 1:5
            left_featureVector_locs(nfeature) = mean(locs(words.WordIndex == nfeature, 2)) / 227;
        end
        
        [right_featureVector, words] = encode(bag, right_uframe, 'UseParallel', 0);
        locs = words.Location;
        clear right_featureVector_locs
        for nfeature = 1:5
            right_featureVector_locs(nfeature) = mean(locs(words.WordIndex == nfeature, 2)) / 227;
        end
        
        rl_next_state = [left_featureVector left_featureVector_locs right_featureVector right_featureVector_locs];
    end
    
    if ~exist('rl_state', 'var')
        rl_state = rl_next_state;
    end
    
    rl_tuple = {rl_state, rl_action, rl_reward, rl_next_state};
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

if save_experiences >= 1

    if rak_only || use_esp32
        fname = strcat('.\Experiences\', this_time, '-', brain_name, '-', num2str(xstep), '-serial_data.mat');
        save(fname, 'serial_data', '-mat');
    end

end

