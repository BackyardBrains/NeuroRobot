
%% Collapser

close all
clear
clc


dataset_dir_name = '.\Datasets\';
rec_dir_name = '';
workspace_dir_name = '.\Workspace\';
nets_dir_name = '.\Nets\';

image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*.png'));
serial_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*serial_data.mat'));

nimages = size(image_dir, 1);
ntuples = size(serial_dir, 1);
disp(horzcat('nimages: ', num2str(nimages)))
disp(horzcat('ndists: ', num2str(ntuples)))

%%
for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/100))
        disp(horzcat('Counter: ', num2str(round(100*(ntuple/ntuples))), '%, ntuple: ', num2str(ntuple)))
    end

    this_ind = ntuple*2-1;    
    left_im_link = strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name);
    left_im = imread(left_im_link);
    left_im = imresize(left_im, [100 100]);
    imwrite(left_im, left_im_link);
    
    this_ind = ntuple*2;
    right_im_link = strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name);
    right_im = imread(right_im_link);
    right_im = imresize(right_im, [100 100]);
    imwrite(right_im, right_im_link);

%     new_im = zeros(227, 302, 3, 'uint8');
%     this_name = serial_dir(ntuple).name;
%     this_name(end-14:end) = [];
%     fname = strcat(serial_dir(ntuple).folder, '\', this_name, 'binoc.png');
%     delete(left_im_link)
%     delete(right_im_link)

end
