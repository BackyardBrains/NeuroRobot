
imdim = 227;

image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*.png'));

rak_cam_h = 227;
rak_cam_w = 302;
large_frame = zeros(rak_cam_h, rak_cam_w, 3, 'uint8');

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/100))
        disp(horzcat('Counter: ', num2str(round(100*(ntuple/ntuples))), '%, ntuple: ', num2str(ntuple)))
    end

    this_ind = ntuple*2-1;    
    left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    left_im = imresize(left_im, [imdim imdim]);

    this_ind = ntuple*2;
    right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    right_im = imresize(right_im, [imdim imdim]);

    large_frame(:, 1:rak_cam_h, :) = left_im;
    large_frame(:, 76:rak_cam_w, :) = right_im;

    if ntuple > 10000
        fnum = '';
    elseif ntuple > 1000
        fnum = '0';
    elseif ntuple > 100
        fnum = '00';
    elseif ntuple > 10
        fnum = '000';
    else
        fnum = '0000';
    end

    fname = strcat(image_dir(this_ind).folder, '\large_frame_', fnum, num2str(ntuple), '_x.png');
    imwrite(large_frame, fname);

end


