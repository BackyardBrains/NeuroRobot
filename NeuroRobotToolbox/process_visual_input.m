
for ncam = 1:2

    if ncam == 1
        uframe = imresize(left_eye_frame, net_input_size);
        frame = single(uframe);
        xframe = imsubtract(prev_left_eye_frame, uframe);
    else
        uframe = imresize(right_eye_frame, net_input_size);
        frame = single(uframe);
        xframe = imsubtract(prev_right_eye_frame, uframe);
    end

    for ncol = 1:3
        if ncol == 1
            colframe = uframe(:,:,1) > uframe(:,:,2) * 1.5 & uframe(:,:,1) > uframe(:,:,3) * 1.5;
            colframe(uframe(:,:,1) < 125) = 0;
        elseif ncol == 2
            colframe = uframe(:,:,2) > uframe(:,:,1) * 1.3 & uframe(:,:,2) > uframe(:,:,3) * 1.3;
            colframe(uframe(:,:,2) < 125) = 0;
        elseif ncol == 3     
            colframe = uframe(:,:,3) > uframe(:,:,2) * 1.4 & uframe(:,:,3) > uframe(:,:,1) * 1.4;
            colframe(uframe(:,:,3) < 125) = 0;
        end
    
        blob = bwconncomp(colframe);
        if blob.NumObjects
            [i, j] = max(cellfun(@numel,blob.PixelIdxList));
            npx = i;
%             disp(horzcat('ncam = ', num2str(ncam), ', ncol = ', num2str(ncol), ', epsp = ', num2str(sigmoid(npx, 1000, 0.0075) * 50)))
            [~, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
            this_score = sigmoid(npx, 1000, 0.0075) * 50;
            this_left_score = sigmoid(((228 - mean(x)) / 227), 0.85, 10) * this_score;
            this_right_score = sigmoid(((mean(x)) / 227), 0.85, 10) * this_score;
        else
            this_score = 0;
            this_left_score = 0;
            this_right_score = 0;
        end
        vis_pref_vals(((ncol - 1) * 3) + 1, ncam) = this_score;
        vis_pref_vals(((ncol - 1) * 3) + 2, ncam) = this_left_score;
        vis_pref_vals(((ncol - 1) * 3) + 3, ncam) = this_right_score;

    end

%     bwframe = rgb2gray(uframe);
%     bwframe(bwframe < 125) = 0;

    xframe = rgb2gray(xframe);
    bwframe = xframe > 40;
    
    blob = bwconncomp(bwframe);
    if blob.NumObjects && ~robot_moving
        [i, j] = max(cellfun(@numel,blob.PixelIdxList));
        npx = i;
    %     disp(horzcat(this_col, ' epsp = ', num2str(sigmoid(npx, 1000, 0.0075) * 50)))
        [~, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
        this_score = sigmoid(npx, 1000, 0.0075) * 50;
        this_left_score = sigmoid(((228 - mean(x)) / 227), 0.85, 10) * this_score;
        this_right_score = sigmoid(((mean(x)) / 227), 0.85, 10) * this_score;
    else
        this_score = 0;
        this_left_score = 0;
        this_right_score = 0;
        x = [0 0 0];
    end

    vis_pref_vals(10, ncam) = this_score;
    vis_pref_vals(11, ncam) = this_left_score;
    vis_pref_vals(12, ncam) = this_right_score;
    
    % Get object classification scores
    if use_cnn
        [label, score] = classify(g_net, frame);  
        cnn_out = sigmoid(score(object_ns), 0.04, 50);
        cnn_out = cnn_out - 0.15;
        cnn_out(cnn_out < 0) = 0;
        vis_pref_vals((n_basic_vis_features+1):n_vis_prefs, ncam) = cnn_out * 50;
    elseif use_rcnn
        try
            aitic = tic;
            
            [bbox, score, label] = detect(trainedDetector, frame, 'NumStrongestRegions', 500, 'threshold', 0, 'ExecutionEnvironment', 'gpu', 'MiniBatchSize', 128);
            [mscore, midx] = max(score);
            mbbox = bbox(midx, :);

            for nobject = 1:n_vis_prefs-n_basic_vis_features
                if ~isempty(max(score(label == object_strs{nobject})))
                    object_scores(nobject) = max(score(label == object_strs{nobject}));
                end
            end
            
            for nobject = 1:n_vis_prefs-n_basic_vis_features
                cnn_out = sigmoid(object_scores(nobject), 0.4, 40) * 50;
                vis_pref_vals(nobject + n_basic_vis_features, ncam) = cnn_out;
            end
            
        catch
            disp('visual processing rcnn break')
        end
    end
    
    if ncam == 1
        prev_left_eye_frame = uframe;
    elseif ncam == 2
        prev_right_eye_frame = uframe;
    end

end

