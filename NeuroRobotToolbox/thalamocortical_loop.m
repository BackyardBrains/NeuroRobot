

% This is all the data saved in Experiences for later hippocampal and basal
% ganglia processing

% Try: Have robot spin round a KNOWN number of times. Label manually and
% compare to autonomous (unsupervised) learning

% special_tic = tic;

if save_experiences == 1

    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));  
    
    [left_featureVector, ~] = encode(bag, left_uframe, 'UseParallel', 0);
    [right_featureVector, ~] = encode(bag, right_uframe, 'UseParallel', 0);
    rl_next_state = [left_featureVector right_featureVector];
    
    % left_featureVector = vis_pref_vals([1 4 7 10],1);
    % right_featureVector = vis_pref_vals([1 4 7 10],2);
    % rl_next_state = [left_featureVector' right_featureVector'];
    
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

elseif save_experiences == 2

    fname = strcat('.\Experiences\',this_time, '-', brain_name, '-', num2str(xstep), '-left_uframe.png');
    imwrite(left_uframe, fname);
    fname = strcat('.\Experiences\', this_time, '-', brain_name, '-', num2str(xstep), '-right_uframe.png');
    imwrite(right_uframe, fname);    
    fname = strcat('.\Experiences\', this_time, '-', brain_name, '-', num2str(xstep), '-this_audio.mat');
    save(fname, 'this_audio', '-mat');    
    fname = strcat('.\Experiences\', this_time, '-', brain_name, '-', num2str(xstep), '-serial_data.mat');
    save(fname, 'serial_data', '-mat');

end

