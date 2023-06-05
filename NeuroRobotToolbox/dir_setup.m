
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

available_brains = dir(strcat(brain_dir, '*.mat'));
if size(available_brains, 1) == 0

    disp('Brain directory is empty')

    load('Lesson1A.mat')
    brain_name = 'Lesson1A';
    load_brain
    save_brain
    load('Lesson1B.mat')
    brain_name = 'Lesson1B';
    load_brain
    save_brain
    load('Lesson2A.mat')
    brain_name = 'Lesson2A';
    load_brain
    save_brain
    load('Lesson2B.mat')
    brain_name = 'Lesson2B';
    load_brain
    save_brain
    load('Lesson3A.mat')
    brain_name = 'Lesson3A';
    load_brain
    save_brain
    load('Lesson3B.mat')
    brain_name = 'Lesson3B';
    load_brain
    save_brain

%     new_brain_vars
%     brain_name = 'Noob';
%     save_brain

    available_brains = dir(strcat(brain_dir, '*.mat'));
    disp(horzcat('Created ', num2str(size(available_brains, 1)), ' new brains'))
    
end


%% Datasets
if isdeployed
    if ispc
        dataset_dir_name = strcat(userpath, '\Datasets\');
    elseif ismac
        dataset_dir_name = strcat(userpath, './Datasets/');
    end
else
    dataset_dir_name = 'C:\SpikerBot ML Datasets\';
    disp(horzcat('Not deployed so using custom Datasets dir: ', dataset_dir_name))
end
    

if ~exist(dataset_dir_name, 'dir')
    mkdir(dataset_dir_name)
    disp('Dataset directory not found')
    disp(horzcat('Created new dataset directory: ', dataset_dir_name))
else
    disp(horzcat('Dataset dir: ', dataset_dir_name))
end

available_rec_dirs = dir(strcat(dataset_dir_name, 'Rec*'));
nrecs = length(available_rec_dirs);


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
else
    disp(horzcat('Workspace directory: ', workspace_dir_name))
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
else
    disp(horzcat('Nets dir: ', nets_dir_name))
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
else
    disp(horzcat('Sounds dir: ', sounds_dir_name))
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
