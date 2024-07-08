

%% Brains
if ispc
    brain_dir = strcat(userpath, '\Brains\');
elseif ismac
    brain_dir = strcat(userpath, '/Brains/');
end

if ~exist(brain_dir, 'dir')
    mkdir(brain_dir)
    disp('Brain directory not found')
    disp(horzcat('Created new brain directory: ', brain_dir))
else
    disp(horzcat('Brain directory: ', brain_dir))
end

brain_name = 'L1E1';
if ~exist(horzcat(brain_dir, brain_name, '.mat'), 'file')
    load(horzcat(brain_name, '.mat'))
    load_brain
    save_brain
end

brain_name = 'L1E2';
if ~exist(horzcat(brain_dir, brain_name, '.mat'), 'file')
    load(horzcat(brain_name, '.mat'))
    load_brain
    save_brain
end

brain_name = 'L1E3';
if ~exist(horzcat(brain_dir, brain_name, '.mat'), 'file')
    load(horzcat(brain_name, '.mat'))
    load_brain
    save_brain
end

brain_name = 'L1E4';
if ~exist(horzcat(brain_dir, brain_name, '.mat'), 'file')
    load(horzcat(brain_name, '.mat'))
    load_brain
    save_brain
end

brain_name = 'L2E3';
if ~exist(horzcat(brain_dir, brain_name, '.mat'), 'file')
    load(horzcat(brain_name, '.mat'))
    load_brain
    save_brain
end

brain_name = 'L1E2R';
if ~exist(horzcat(brain_dir, brain_name, '.mat'), 'file')
    load(horzcat(brain_name, '.mat'))
    load_brain
    save_brain
end

brain_name = 'L2E3R';
if ~exist(horzcat(brain_dir, brain_name, '.mat'), 'file')
    load(horzcat(brain_name, '.mat'))
    load_brain
    save_brain
end

brain_name = 'Marco';
if ~exist(horzcat(brain_dir, brain_name, '.mat'), 'file')
    load(horzcat(brain_name, '.mat'))
    load_brain
    save_brain
end

available_brains = dir(strcat(brain_dir, '*.mat'));


%% Datasets
dataset_dir_name = strcat(userpath, '\Datasets\');
rec_dir_name = '';

if ~exist(dataset_dir_name, 'dir')
    mkdir(dataset_dir_name)
    disp('Dataset directory not found')
    disp(horzcat('Created new dataset directory: ', dataset_dir_name))
else
    disp(horzcat('Dataset dir: ', dataset_dir_name))
end


%% Settings
if ispc
    settings_dir_name = strcat(userpath, '\Settings\');
elseif ismac
    settings_dir_name = strcat(userpath, './Settings/');
end

if ~exist(settings_dir_name, 'dir')
    mkdir(settings_dir_name)
    disp('Settings directory not found')
    disp(horzcat('Created new settings directory: ', settings_dir_name))
end


%% Workspace
if ispc
    workspace_dir_name = strcat(userpath, '\Workspace\');
elseif ismac
    workspace_dir_name = strcat(userpath, './Workspace/');
end

if ~exist(workspace_dir_name, 'dir')
    mkdir(workspace_dir_name)
    disp('Workspace directory not found')
    disp(horzcat('Created new workspace directory: ', workspace_dir_name))
end
  

%% Nets
if ispc
    nets_dir_name = strcat(userpath, '\Nets\');
elseif ismac
    nets_dir_name = strcat(userpath, './Nets/');
end

if ~exist(nets_dir_name, 'dir')
    mkdir(nets_dir_name)
    disp(horzcat('Created new nets directory: ', nets_dir_name))
end


%% Sounds
if ispc
    sounds_dir_name = strcat(userpath, '\Sounds\');
elseif ismac
    sounds_dir_name = strcat(userpath, './Sounds/');
end

if ~exist(sounds_dir_name, 'dir')
    mkdir(sounds_dir_name)
    disp('Sounds directory not found')
    disp(horzcat('Created new sounds directory: ', sounds_dir_name))
end

available_sounds = dir(strcat(sounds_dir_name, '*.wav'));
n_out_sounds = size(available_sounds, 1);

if n_out_sounds == 0
    disp('no wavs found in sounds dir, creating ...')
    load handel
    audiowrite(strcat(sounds_dir_name, 'handel.wav'), y, 16000);
    available_sounds = dir(strcat(sounds_dir_name, '*.wav'));
    n_out_sounds = size(available_sounds, 1);
end
