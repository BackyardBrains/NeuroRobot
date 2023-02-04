
serial_dir = dir(fullfile(strcat(localdata_dir_name, rec_dir_name), '**\*serial_data.mat'));
ntuples = size(serial_dir, 1);
disp(horzcat('N tuples: ', num2str(ntuples)))

image_ds = imageDatastore(strcat(localdata_dir_name, rec_dir_name), 'FileExtensions', '.png', 'IncludeSubfolders', 1);
image_ds.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually - This is where some images get saved small
% save(strcat(localdata_dir_name, 'image_ds'), 'image_ds')

nimages = length(image_ds.Files);
disp(horzcat('N images: ', num2str(nimages)))

small_inds = randsample(ntuples, nsmall);
medium_inds = randsample(ntuples, nmedium);
image_ds_small = subset(image_ds, small_inds*2);
image_ds_medium = subset(image_ds, medium_inds*2);
image_ds_small.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
image_ds_medium.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
% save(strcat(localdata_dir_name, 'image_ds_small'), 'image_ds_small')
% save(strcat(localdata_dir_name, 'image_ds_medium'), 'image_ds_medium')

ps = parallel.Settings;
ps.Pool.AutoCreate = false;
ps.Pool.IdleTimeout = Inf;

bag = bagOfFeatures(image_ds_small, 'treeproperties', [1 25]);
% save(strcat(localdata_dir_name, 'bag'), 'bag')

imageIndex = indexImages(image_ds_medium, bag);
% save(strcat(localdata_dir_name, 'imageIndex'), 'imageIndex')

serial_dir = dir(fullfile(strcat(localdata_dir_name, rec_dir_name), '**\*serial_data.mat'));
get_dists

get_image_crosscorr
% save(strcat(localdata_dir_name, 'xdata_L1'), 'xdata', '-v7.3')
% save(strcat(localdata_dir_name, 'xdata_cosine'), 'xdata', '-v7.3')
