

image_ds = imageDatastore(strcat(data_dir_name, rec_dir_name), 'FileExtensions', '.png', 'IncludeSubfolders', 1);
image_ds.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually - This is where some images get saved small
save(strcat(data_dir_name, 'image_ds'), 'image_ds')

nimages = length(image_ds.Files);
disp(horzcat('N images: ', num2str(nimages)))

image_ds_small = subset(image_ds, randsample(nimages, nsmall));
image_ds_medium = subset(image_ds, randsample(nimages, nmedium));
image_ds_small.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
image_ds_medium.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
save(strcat(data_dir_name, 'image_ds_small'), 'image_ds_small')
save(strcat(data_dir_name, 'image_ds_medium'), 'image_ds_medium')

ps = parallel.Settings;
ps.Pool.AutoCreate = false;
ps.Pool.IdleTimeout = Inf;

bag = bagOfFeatures(image_ds_small, 'treeproperties', [2 200]);
save(strcat(data_dir_name, 'bag'), 'bag')

imageIndex = indexImages(image_ds_medium, bag);
save(strcat(data_dir_name, 'imageIndex'), 'imageIndex')

get_image_crosscorr
% save(strcat(data_dir_name, 'xdata_L1'), 'xdata', '-v7.3')
save(strcat(data_dir_name, 'xdata_cosine'), 'xdata', '-v7.3')
