


% Get all recorded data and display summary stats
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
ntuples = nimages;

if ntuples ~= ndists || ntuples ~= ntorques
    error('nimages, ndists, ntorques, ntuples - size mismatch')
end

this_msg = horzcat('Found data from = ', num2str(ntuples), ' time points');
tx1.String = this_msg;
drawnow
disp(this_msg)

