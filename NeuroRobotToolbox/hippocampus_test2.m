
clear
clc

imdim = 100;
data_dir_name = 'C:\Users\Christopher Harris\Dataset 1\';
rec_dir_name = '';

nsmall = 2000;
nmedium = 10000;

load(strcat(data_dir_name, 'image_ds'))
load(strcat(data_dir_name, 'bag'))
load(strcat(data_dir_name, 'imageIndex'))
load(strcat(data_dir_name, 'xdata'))