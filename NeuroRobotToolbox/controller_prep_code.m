% Get workspace directory
if ispc && ~isdeployed
    workspace_dir_name = '.\Workspace\';
elseif ispc && isdeployed          
    workspace_dir_name = strcat(userpath, '\Workspace\');
    if ~exist(workspace_dir_name, 'dir')
        mkdir(workspace_dir_name)
        disp(horzcat('Created new workspace directory: ', workspace_dir_name))
    end
elseif ismac && ~isdeployed
    workspace_dir_name = './Workspace/';
elseif ismac && isdeployed
    disp('Error: app compiled for Windows')
end
disp(horzcat('Workspace dir: ', workspace_dir_name))   

% Get nets directory
if ispc && ~isdeployed
    nets_dir_name = '.\Nets\';
elseif ispc && isdeployed        
    nets_dir_name = strcat(userpath, '\Nets\');
    if ~exist(nets_dir_name, 'dir')
        mkdir(nets_dir_name)
        disp(horzcat('Created new nets directory: ', nets_dir_name))
    end
elseif ismac && ~isdeployed
    nets_dir_name = './Nets/';
elseif ismac && isdeployed
    disp('Error: app compiled for Windows')
end
disp(horzcat('Nets dir: ', nets_dir_name))                 
load(strcat(nets_dir_name, net_name, '-net'))
load(strcat(nets_dir_name, net_name, '-labels'))
unique_states = unique(labels);
n_unique_states = length(unique_states);
load(horzcat(nets_dir_name, net_name, '-RL-', agent_name))
load(strcat(nets_dir_name, net_name, '-torque_data'))
load(strcat(nets_dir_name, net_name, '-actions'))
n_unique_actions = length(unique(actions));
motor_combs = zeros(n_unique_actions, 2);
for naction = 1:n_unique_actions
    motor_combs(naction, :) = mean(torque_data(actions == naction, :), 1);
end

state_wavs = struct;
for nstate = 1:n_unique_states
    word_name = char(labels(nstate));
    word_name(word_name == '-') = ' ';
    this_wav_m = tts(word_name,'Microsoft David Desktop - English (United States)',[],16000);
    this_wav_f = tts(word_name,'Microsoft Zira Desktop - English (United States)',[],16000);
    if length(this_wav_m) > length(this_wav_f)
        this_wav_m = this_wav_m(1:length(this_wav_f));
    else
        this_wav_f = this_wav_f(1:length(this_wav_m));
    end
    this_wav = this_wav_f + this_wav_m;
    state_wavs(nstate).wav = this_wav;
end