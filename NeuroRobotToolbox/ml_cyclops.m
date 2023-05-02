
imdim = 100;
% image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*.png'));
data = zeros(ntuples, 2);
counter = 0;
prev_folder = '';
clear fnames;

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/1000))
        disp(horzcat('Counter: ', num2str(round(100*(ntuple/ntuples))), '%, ntuple: ', num2str(ntuple), ' counter: ', num2str(counter)))
    end

    this_ind = ntuple*2-1;    
    left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    left_im = imresize(left_im, [imdim imdim]);

    this_ind = ntuple*2;
    right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    right_im = imresize(right_im, [imdim imdim]);

    this_folder = image_dir(this_ind).folder;

    if ~strcmp(this_folder, prev_folder)
        counter = counter + 1;
%         fnames{counter} = this_folder;
        prev_folder = this_folder;
    end

%     left_stripe = double(left_im(:,end,:));
%     stripe_data = zeros(100,1);
%     for ii = 1:100
%         right_stripe = double(right_im(:,ii,:));
%         diff_stripe = abs(left_stripe - right_stripe);
%         stripe_data(ii) = mean(diff_stripe(:));
%     end
%     [i, j] = min(stripe_data);
%     data(ntuple, 1) = j;
%     data(ntuple, 2) = counter;
    
    if data2(counter) < 40
        rak_cam_h = 100;
        rak_cam_w = 178;
        large_frame = zeros(rak_cam_h, rak_cam_w, 3, 'uint8');
        large_frame(:, 1:100, :) = left_im;
        large_frame(:, 79:178, :) = right_im; 
    else
        rak_cam_h = 100;
        rak_cam_w = 133;
        large_frame = zeros(rak_cam_h, rak_cam_w, 3, 'uint8');
        large_frame(:, 1:100, :) = left_im;
        large_frame(:, 34:133, :) = right_im;
    end

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


%%
% data2 = zeros(counter, 1);
% for ii = 1:counter
%     inds = find(data(:,2) == ii);
%     data2(ii) = median(data(inds, 1));
% end

