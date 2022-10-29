
imdim = 100;
states = zeros(ntuples, 1);
for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(horzcat('Counter: ', num2str(round(100*(ntuple/ntuples))), '%, ntuple: ', num2str(ntuple)))
    end

    this_ind = ntuple*2-1;    
    left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    left_im = imresize(left_im, [imdim imdim]);

    this_ind = ntuple*2;
            
    right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    right_im = imresize(right_im, [imdim imdim]);
    
    uframe = imresize(large_frame, [404 227]);
    colframe = uframe(:,:,1) > uframe(:,:,2) * 1.5 & uframe(:,:,1) > uframe(:,:,3) * 1.5;
    colframe(uframe(:,:,1) < 75) = 0;

    blob = bwconncomp(colframe);
    if blob.NumObjects
        [i, j] = max(cellfun(@numel,blob.PixelIdxList));
        npx = i;
        [~, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
    else
        x = 0;
    end

    avg_x = round(mean(x));
    disp(horzcat('avg red x: ', num2str(avg_x)))
    
    states(ntuple) = avg_x;

end

