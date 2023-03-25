
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

this_msg = horzcat('nimages = ', num2str(nimages), ', ndists = ', num2str(ndists), ', ntorques = ', num2str(ntorques));
tx1.String = this_msg;
drawnow
disp(this_msg)
