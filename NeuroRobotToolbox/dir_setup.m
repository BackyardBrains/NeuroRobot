
%% Brains
if ispc
    brain_dir = strcat(userpath, '\Brains\');
elseif ismac && ~isdeployed
    brain_dir = strcat(userpath, '/Brains/');
elseif ismac && isdeployed
    disp('Error: app is compiled for Windows')
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
    new_brain_vars
    brain_name = 'Noob';
    save_brain
    disp('Brain directory is empty')
    disp(horzcat('Created new brain: ', brain_name))
    available_brains = dir(strcat(brain_dir, '*.mat'));
end


%% Datasets
if ispc
    dataset_dir_name = strcat(userpath, '\Datasets\');
elseif ismac && ~isdeployed
    dataset_dir_name = strcat(userpath, './Datasets/');
elseif ismac && isdeployed
    disp('Error: app is compiled for Windows')
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
elseif ismac && ~isdeployed
    workspace_dir_name = strcat(userpath, './Workspace/');
elseif ismac && isdeployed
    disp('Error: app is compiled for Windows')
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
elseif ismac && ~isdeployed
    nets_dir_name = strcat(userpath, './Nets/');
elseif ismac && isdeployed
    disp('Error: app is compiled for Windows')
end

if ~exist(nets_dir_name, 'dir')
    mkdir(nets_dir_name)
    disp(horzcat('Created new nets directory: ', nets_dir_name))
else
    disp(horzcat('Nets dir: ', nets_dir_name))
end

