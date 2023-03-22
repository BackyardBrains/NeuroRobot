
%% Get all recorded data and display summary stats

axes(ax1)

cla
tx1 = text(0.03, 0.5, horzcat('finding recorded data...'));
drawnow

image_ds = imageDatastore(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*.png'));
image_ds.ReadFcn = @customReadFcn; % imdim = 100
nimages = length(image_ds.Files);

tx1.String = horzcat('nimages = ', num2str(nimages), ', still processing...');
drawnow

serial_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*serial_data.mat'));
torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));

ndists = size(serial_dir, 1);
ntorques = size(torque_dir, 1);
ntuples = nimages/2;

tx1.String = horzcat('nimages = ', num2str(nimages), ', ndists = ', num2str(ndists), ', ntorques = ', num2str(ntorques));
drawnow
