

%% Get directory
if alearn_data_select.Value > 1
    rec_dir_name = available_datasets{alearn_data_select.Value};
else
    rec_dir_name = '';
end


%% Get all recorded data and display summary stats
axes(alearn_data_status_ax)

this_msg = 'Finding training data...';
cla
tx1 = text(0.03, 0.5, this_msg);
drawnow
disp(this_msg)

try
    image_ds = imageDatastore(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*.png'));
catch
    error('Datasets folder is missing or empty')
end
image_ds.ReadFcn = @customReadFcn; % imdim = 224
nimages = length(image_ds.Files);

serial_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*serial_data.mat'));
torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));

ndists = size(serial_dir, 1);
ntorques = size(torque_dir, 1);
ntuples = nimages/2;

if ntuples ~= ndists || ntuples ~= ntorques
    error('nimages, ndists, ntorques, ntuples - size mismatch')
end

this_msg = horzcat('Ready to process ', num2str(nimages), ' images');
tx1.String = this_msg;
drawnow
disp(this_msg)

