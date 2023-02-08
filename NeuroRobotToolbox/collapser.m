
close all
clear
clc

localdata_dir_name = 'C:\Users\Christopher Harris\Dataset2a\';
rec_dir_name = '';
image_dir = dir(fullfile(strcat(localdata_dir_name, rec_dir_name), '**\*.png'));
nimages = size(image_dir, 1);
disp(horzcat('nimages: ', num2str(nimages)))
delete(strcat(localdata_dir_name, rec_dir_name, '*binoc.png'))
disp(horzcat('nimages: ', num2str(nimages)))

serial_dir = dir(fullfile(strcat(localdata_dir_name, rec_dir_name), '**\*serial_data.mat'));
ntuples = size(serial_dir, 1);
disp(horzcat('ndists: ', num2str(ntuples)))

%%
for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/100))
        disp(horzcat('Counter: ', num2str(round(100*(ntuple/ntuples))), '%, ntuple: ', num2str(ntuple)))
    end

    new_im = zeros(227, 404, 3, 'uint8');

    this_ind = ntuple*2-1;    
    left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
%     left_im = imresize(left_im, [imdim imdim]);

    this_ind = ntuple*2;
    right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
%     right_im = imresize(right_im, [imdim imdim]);

    new_im(:, 1:227, :) = left_im;
    new_im(:, 178:404, :) = right_im;    

    this_name = serial_dir(ntuple).name;
    this_name(end-14:end) = [];
    fname = strcat(serial_dir(ntuple).folder, '\', this_name, num2str(ntuple), 'binoc.png');
    imwrite(new_im, fname);

end
