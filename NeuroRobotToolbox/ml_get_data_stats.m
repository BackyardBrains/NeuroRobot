
%% Get all recorded data and display summary stats

axes(ax1)

this_msg = 'finding recorded data...';
cla
tx1 = text(0.03, 0.5, this_msg);
drawnow
disp(this_msg)

image_ds = imageDatastore(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*.png'));
image_ds.ReadFcn = @customReadFcn; % imdim = 100
nimages = length(image_ds.Files);

this_msg = horzcat('nimages = ', num2str(nimages), ', still processing...');
tx1.String = this_msg;
drawnow
disp(this_msg)

serial_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*serial_data.mat'));
torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));

ndists = size(serial_dir, 1);
ntorques = size(torque_dir, 1);
ntuples = nimages/2;

if ntuples ~= ndists || ntuples ~= ntorques
    error('nimages, ndists, ntorques, ntuples - size mismatch')
end

this_msg = horzcat('ntuples = ', num2str(ntuples));
tx1.String = this_msg;
drawnow
disp(this_msg)

%% Set ML parameters
nsmall = round(0.01527 * ntuples + 694.7);
nmedium = round(0.03053 * ntuples + 1389);
bof_branching = round(0.001527 * ntuples + 69.47);
init_n_unique_states = round(0.001527 * ntuples + 69.47);
min_size = round(0.00005 * ntuples + 19);

disp('')
disp('ML parameters')
disp('-------------')
disp(horzcat('nsmall = ', num2str(nsmall)))
disp(horzcat('nmedium = ', num2str(nmedium)))
disp(horzcat('bof_branching = ', num2str(bof_branching)))
disp(horzcat('init_n_unique_states = ', num2str(init_n_unique_states)))
disp(horzcat('min_size = ', num2str(min_size)))
disp('')
