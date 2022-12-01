
% This script will extract a new random subset of N tuples from Database 1
% on laptop-main and write them to a new folder for easy USB transport to
% other laptops

clear
clc

nsmall = 10000;
nmedium = 20000;

imdim = 100;
localdata_dir_name = 'C:\Users\Christopher Harris\Dataset 1\';
rec_dir_name = 'PreTraining\';
extra_dir_name = 'Classifier\';
new_data_dir_name = 'D:\';

image_dir = dir(fullfile(strcat(data_dir_name, rec_dir_name), '**\*.png'));
nimages = size(image_dir, 1);
ntuples = nimages/2;

inds_small = randsample(ntuples, nsmall);
inds_medium = randsample(ntuples, nmedium);

mkdir(strcat(new_data_dir_name, extra_dir_name))
for n = 1:nsmall
    this_ind = inds_small(n)*2-1;
    this_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    fname = strcat(new_data_dir_name, extra_dir_name, 'im', num2str(this_ind), '.png');
    imwrite(this_im, fname);
end


image_ds = imageDatastore(strcat(localdata_dir_name, rec_dir_name), 'FileExtensions', '.png', 'IncludeSubfolders', 1);
image_ds.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually - This is where some images get saved small

nimages = length(image_ds.Files);
disp(horzcat('N images: ', num2str(nimages)))

image_ds_small = subset(image_ds, 100); % should not be 100
image_ds_medium = subset(image_ds, 100); % should not be 100
image_ds_small.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
image_ds_medium.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
save(strcat(new_data_dir_name, 'image_ds_small'), 'image_ds_small')
save(strcat(new_data_dir_name, 'image_ds_medium'), 'image_ds_medium')

