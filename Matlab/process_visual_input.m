
for ncam = 1:2

    if ncam == 1
        frame = single(left_eye_frame);
        temporal_pxs = 1:200;
    else
        frame = single(right_eye_frame);
        temporal_pxs = 301:500;
    end

    % Red
    red = frame(:,:,1) > frame(:,:,2) * 2 & frame(:,:,1) > frame(:,:,3) * 2;
    red(frame(:,:,1) < 50) = 0;
    
    blob = bwconncomp(red);
    if blob.NumObjects
        npx = max(cellfun(@numel,blob.PixelIdxList));
    else
        npx = 0;
    end
    vis_pref_vals(1, ncam) = sigmoid(npx, 5000, 0.001) * 50;
    
    blob = bwconncomp(red(:, temporal_pxs));
    if blob.NumObjects
        npx = max(cellfun(@numel,blob.PixelIdxList));
    else
        npx = 0;
    end
    vis_pref_vals(4, ncam) = sigmoid(npx, 5000, 0.001) * 50;
    
    % Green
    green = frame(:,:,2) > frame(:,:,1) * 1.5 & frame(:,:,2) > frame(:,:,3) * 1.5;
    green(frame(:,:,2) < 50) = 0;
    
    blob = bwconncomp(green);
    if blob.NumObjects
        npx = max(cellfun(@numel,blob.PixelIdxList));
    else
        npx = 0;
    end
    vis_pref_vals(2, ncam) = sigmoid(npx, 5000, 0.001) * 50;
    
    blob = bwconncomp(green(:, temporal_pxs));
    if blob.NumObjects
        npx = max(cellfun(@numel,blob.PixelIdxList));
    else
        npx = 0;
    end
    vis_pref_vals(5, ncam) = sigmoid(npx, 5000, 0.001) * 50;
    
    % Blue
    blue = frame(:,:,3) > frame(:,:,2) * 1.5 & frame(:,:,3) > frame(:,:,1) * 1.5;
    blue(frame(:,:,3) < 50) = 0;
    
    blob = bwconncomp(blue);
    if blob.NumObjects
        npx = max(cellfun(@numel,blob.PixelIdxList));
    else
        npx = 0;
    end
    vis_pref_vals(3, ncam) = sigmoid(npx, 5000, 0.001) * 50;
    
    blob = bwconncomp(blue(:, temporal_pxs));
    if blob.NumObjects
        npx = max(cellfun(@numel,blob.PixelIdxList));
    else
        npx = 0;
    end
    vis_pref_vals(6, ncam) = sigmoid(npx, 5000, 0.001) * 50;

    % Get object classification scores
    if use_cnn
        frame_small = imresize(frame, net_input_size);
        [label, score] = classify(net, frame_small);   
        vis_pref_vals(7:n_vis_prefs, ncam) = sigmoid(score(object_ns), 0.12, 100) * 50;
    end
end


