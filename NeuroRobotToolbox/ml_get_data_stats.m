

%% Get all recorded data and display summary stats
axes(ml_train1_status)

this_msg = 'Finding recorded data...';
cla
tx1 = text(0.03, 0.5, this_msg, 'fontsize', bfsize + 4);
drawnow
disp(this_msg)

try
    image_ds = imageDatastore(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*_x.png'));
catch
    error('Datasets folder is missing or empty')
end
image_ds.ReadFcn = @customReadFcn; % imdim = 224
nimages = length(image_ds.Files);

serial_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*serial_data.mat'));
torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));

ndists = size(serial_dir, 1);
ntorques = size(torque_dir, 1);
% ntuples = nimages/2;
ntuples = nimages;

if ntuples ~= ndists || ntuples ~= ntorques
    error('nimages, ndists, ntorques, ntuples - size mismatch')
end

this_msg = horzcat('Found data from = ', num2str(ntuples), ' time points');
tx1.String = this_msg;
drawnow
disp(this_msg)


%% Set ML parameters
nsmall = round((0.001 * ntuples + 1000) * learn_speed * 2);
bof_branching = round((0.0003 * ntuples + 200) * learn_speed);
nmedium = round((0.005 * ntuples + 2000) * learn_speed);
init_n_unique_states = round(0.0005 * ntuples * learn_speed) + 10 * learn_speed;
min_size = round(0.00008 * ntuples * learn_speed) + 9 * learn_speed;
        
disp('')
disp('PARAMETER SETTINGS:')
disp(horzcat('nsmall = ', num2str(nsmall)))
disp(horzcat('nmedium = ', num2str(nmedium)))
disp(horzcat('bof_branching = ', num2str(bof_branching)))
disp(horzcat('init_n_unique_states = ', num2str(init_n_unique_states)))
disp(horzcat('min_size = ', num2str(min_size)))

