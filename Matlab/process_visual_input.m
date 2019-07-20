
for ncam = 1:2

    if ncam == 1
        frame = single(left_eye_frame);
%         temporal_pxs = 1:200;
        temporal_pxs = 1:200;
    else
        frame = single(right_eye_frame);
%         temporal_pxs = 301:500;
        temporal_pxs = 134:224;
    end
    
    frame = imresize(frame, net_input_size);

    % Red
    red = frame(:,:,1) > frame(:,:,2) * 2 & frame(:,:,1) > frame(:,:,3) * 2;
    red(frame(:,:,1) < 50) = 0;
    
    blob = bwconncomp(red);
    if blob.NumObjects
        [i, j] = max(cellfun(@numel,blob.PixelIdxList));
        npx = i;
        [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
        this_score = sigmoid(npx, 5000, 0.001) * 50;
        if ncam == 1
            temporal_score = sigmoid(((227 - mean(x)) / 227), 0.7, 10) * this_score;
        elseif ncam == 2
            temporal_score = sigmoid((mean(x) / 227), 0.7, 10) * this_score;
        end        
    else
        this_score = 0;
    end
    vis_pref_vals(1, ncam) = this_score;
    vis_pref_vals(2, ncam) = temporal_score;
    
    % Green
    green = frame(:,:,2) > frame(:,:,1) * 1.5 & frame(:,:,2) > frame(:,:,3) * 1.5;
    green(frame(:,:,2) < 50) = 0;
    
    blob = bwconncomp(green);
    if blob.NumObjects
        [i, j] = max(cellfun(@numel,blob.PixelIdxList));
        npx = i;
        [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
        this_score = sigmoid(npx, 5000, 0.001) * 50;
        if ncam == 1
            temporal_score = sigmoid(((227 - mean(x)) / 227), 0.7, 10) * this_score;
        elseif ncam == 2
            temporal_score = sigmoid((mean(x) / 227), 0.7, 10) * this_score;
        end         
    else
        this_score = 0;
    end
    vis_pref_vals(3, ncam) = this_score;
    vis_pref_vals(4, ncam) = temporal_score;
    
    % Blue
    blue = frame(:,:,3) > frame(:,:,2) * 1.5 & frame(:,:,3) > frame(:,:,1) * 1.5;
    blue(frame(:,:,3) < 50) = 0;
    
    blob = bwconncomp(blue);
    if blob.NumObjects
        [i, j] = max(cellfun(@numel,blob.PixelIdxList));
        npx = i;
        [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
        this_score = sigmoid(npx, 5000, 0.001) * 50;
        if ncam == 1
            temporal_score = sigmoid(((227 - mean(x)) / 227), 0.7, 10) * this_score;
        elseif ncam == 2
            temporal_score = sigmoid((mean(x) / 227), 0.7, 10) * this_score;
        end        
    else
        this_score = 0;
    end
    vis_pref_vals(5, ncam) = this_score;
    vis_pref_vals(6, ncam) = temporal_score;

    % Get object classification scores
    if use_cnn
        [label, score] = classify(net, frame);  
        cnn_out = sigmoid(score(object_ns), 0.04, 50);
        cnn_out = cnn_out - 0.15;
        cnn_out(cnn_out < 0) = 0;
        vis_pref_vals(7:n_vis_prefs, ncam) = cnn_out * 50;
    elseif use_rcnn
        try
%             [bbox, score] = detect(rcnn, frame, 'NumStrongestRegions', 100, 'MiniBatchSize', 32, 'ExecutionEnvironment', 'gpu');
            [bbox, score] = detect(rcnn, frame, 'ExecutionEnvironment', 'gpu');
            if isempty(bbox)
                score = 0;
            end
            if length(score) > 1
                [score, idx] = max(score);
                bbox = bbox(idx, :);
            end
            cnn_out = sigmoid(score, 0.75, 40) * 50;
%             vis_pref_vals(7:n_vis_prefs, ncam) = cnn_out;
            vis_pref_vals(7, ncam) = cnn_out;
            if ~isempty(bbox)
                if ncam == 1
                    this_val = ((227 - (bbox(1) + (bbox(3) / 2))) / 227);
                    temporal_cnn_out = cnn_out * sigmoid(this_val, 0.7, 10);
                elseif ncam == 2
                    this_val = ((bbox(1) + (bbox(3) / 2)) / 227);
                    temporal_cnn_out = cnn_out * sigmoid(this_val, 0.7, 10);
                end
            else
                temporal_cnn_out = 0;
            end
            vis_pref_vals(8, ncam) = temporal_cnn_out;
            disp(horzcat('final neurorobot signal = ', num2str(cnn_out), ', detector score = ', num2str(score)))
        catch
            disp('break')
        end
    end
end


