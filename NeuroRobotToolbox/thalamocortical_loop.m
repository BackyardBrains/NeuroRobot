

% Hypothesis: Have robot spin round a KNOWN number of times. Label manually
% (supervised learning) or learn autonomously.

% This is what's going to become cortex

% CORTEX CORTEX CORTEX 



% special_tic = tic;
this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));  

% fname = strcat('.\Experiences\',this_time, '-', brain_name, '-', num2str(xstep), '-left_uframe.png');
% imwrite(left_uframe, fname);
% fname = strcat('.\Experiences\', this_time, '-', brain_name, '-', num2str(xstep), '-right_uframe.png');
% imwrite(right_uframe, fname);    
% fname = strcat('.\Experiences\', this_time, '-', brain_name, '-', num2str(xstep), '-this_audio.mat');
% save(fname, 'this_audio', '-mat');    
% fname = strcat('.\Experiences\', this_time, '-', brain_name, '-', num2str(xstep), '-serial_data.mat');
% save(fname, 'serial_data', '-mat');

% [left_featureVector, ~] = encode(bag, left_uframe, 'UseParallel', 0);
% [right_featureVector, ~] = encode(bag, right_uframe, 'UseParallel', 0);
% rl_next_state = [left_featureVector right_featureVector];

left_featureVector = vis_pref_vals([1 4 7 10],1);
right_featureVector = vis_pref_vals([1 4 7 10],2);
rl_next_state = [left_featureVector' right_featureVector'];

if ~exist('rl_state', 'var')
    rl_state = rl_next_state;
end

rl_tuple = {rl_state, rl_action, rl_reward, rl_next_state};
file_name = strcat('.\Experiences\', this_time, '-', brain_name, '-', num2str(xstep), '-tuple.mat');
save(file_name, 'rl_tuple', '-mat')
rl_state = rl_next_state;
rl_action = [left_torque_mem right_torque_mem]; % this_network? % this will need binarization later

rl_reward = reward; % should this be from the next time step or somethimng?


% toc(special_tic)

