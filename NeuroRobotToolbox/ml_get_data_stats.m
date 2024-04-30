

% Get all recorded data and display summary stats
axes(ml_train1_status)

this_msg = 'Finding recorded data...';
cla
tx1 = text(0.03, 0.5, this_msg, 'fontsize', bfsize + 4);
drawnow
disp(this_msg)

%% Loader
ml_data_type = 0;

try
    torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torque.txt'));
    serial_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*serial.txt'));
    image_ds = imageDatastore(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*large_frame_x.jpg'));
    ml_data_type = 1;
    disp('Datasets found and indexed (adapted type 1)')
catch
end

try
    image_ds = imageDatastore(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*large_frame_x.png'));
    serial_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*serial_data.mat'));
    torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));
    ml_data_type = 2;
    disp('Datasets found and indexed (original type)')
catch
end

% try
    % image_ds = imageDatastore(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*large_frame_x.png'));
    % serial_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*serial_data.mat'));
    % torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));

    % Not yet implemented

    % ml_data_type = 3;
    % disp('Datasets found and indexed (adapted type 2)')
% catch
% end

nimages = length(image_ds.Files);

if ~ml_data_type || ~nimages
    error('Datasets not found')
end

nserial = size(serial_dir, 1);
ntorques = size(torque_dir, 1);
ntuples = nimages;

if ntuples ~= nserial || ntuples ~= ntorques
    error('nimages, ndists, ntorques, ntuples - size mismatch')
end

this_msg = horzcat('ntuples: ', num2str(ntuples));
disp(this_msg)

