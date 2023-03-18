% Get dataset directory
if ispc && ~isdeployed
    dataset_dir_name = '.\Datasets\';
elseif ispc && isdeployed        
    dataset_dir_name = strcat(userpath, '\Datasets\');
    if ~exist(dataset_dir_name, 'dir')
        mkdir(dataset_dir_name)
        disp(horzcat('Created new dataset directory: ', dataset_dir_name))
    end
elseif ismac && ~isdeployed
    dataset_dir_name = './Datasets/';
elseif ismac && isdeployed
    disp('Error: app compiled for Windows')
end
disp(horzcat('Dataset dir: ', dataset_dir_name))            

% Get recording directory
available_rec_dirs = dir(strcat(dataset_dir_name, 'Rec*'));
nrecs = length(available_rec_dirs);