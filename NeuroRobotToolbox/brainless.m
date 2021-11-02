

%% Frame
this_frame = imresize(large_frame, 0.315);
this_frame = single(this_frame);

%% Red
red = this_frame(:,:,1) > this_frame(:,:,2) * 1.8 & this_frame(:,:,1) > this_frame(:,:,3) * 1.8;
red(this_frame(:,:,1) < 50) = 0;
blob = bwconncomp(red);
if blob.NumObjects
    [i, j] = max(cellfun(@numel,blob.PixelIdxList));
    npx = i;
    [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
    red_max = sigmoid(npx, 1000, 0.01) * 50;
    if npx > 1
        red_loc = mean(x);
    else
        red_loc = x; 
    end
else
    red_max = 0;
    red_loc = 202;
end


%% Green
green = frame(:,:,2) > frame(:,:,1) * 1.2 & frame(:,:,2) > frame(:,:,3) * 1.2;
green(frame(:,:,2) < 50) = 0;
blob = bwconncomp(green);
if blob.NumObjects
    [i, j] = max(cellfun(@numel,blob.PixelIdxList));
    npx = i;
    [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
    green_max = sigmoid(npx, 1000, 0.01) * 50;
    if npx > 1
        green_loc = mean(x);
    else
        green_loc = x; 
    end    
else
    green_max = 0;
    green_loc = 202;
end

%% Blue
blue = frame(:,:,3) > frame(:,:,2) * 1.5 & frame(:,:,3) > frame(:,:,1) * 1.5;
blue(frame(:,:,3) < 50) = 0;
blob = bwconncomp(blue);
if blob.NumObjects
    [i, j] = max(cellfun(@numel,blob.PixelIdxList));
    npx = i;
    [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
    blue_max = sigmoid(npx, 1000, 0.01) * 50;
    if npx > 1
        blue_loc = mean(x);
    else
        blue_loc = x; 
    end    
else
    blue_max = 0;
    blue_loc = 202;
end


%%