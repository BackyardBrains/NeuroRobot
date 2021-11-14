
for ncam = 1:2

    if ncam == 1
        uframe = imresize(left_eye_frame, net_input_size);
        frame = single(uframe);
    else
        uframe = imresize(right_eye_frame, net_input_size);
        frame = single(uframe);
    end

    % Red
    red = frame(:,:,1) > frame(:,:,2) * 1.8 & frame(:,:,1) > frame(:,:,3) * 1.8;
    red(frame(:,:,1) < 50) = 0;
    
    blob = bwconncomp(red);
    if blob.NumObjects
        [i, j] = max(cellfun(@numel,blob.PixelIdxList));
        npx = i;
        [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
        this_score = sigmoid(npx, 1000, 0.01) * 50;
%         if ncam == 1
%             temporal_score = sigmoid(((227 - mean(x)) / 227), 0.95, 5) * this_score;
%         elseif ncam == 2
%             temporal_score = sigmoid((mean(x) / 227), 0.95, 5) * this_score;
%         end        
    else
        this_score = 0;
%         temporal_score = 0;
    end
    vis_pref_vals(1, ncam) = this_score;
%     vis_pref_vals(2, ncam) = temporal_score;
    
  
    % Green
    green = frame(:,:,2) > frame(:,:,1) * 1.2 & frame(:,:,2) > frame(:,:,3) * 1.2;
    green(frame(:,:,2) < 50) = 0;
    
    blob = bwconncomp(green);
    if blob.NumObjects
        [i, j] = max(cellfun(@numel,blob.PixelIdxList));
        npx = i;
        [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
        this_score = sigmoid(npx, 1000, 0.01) * 50;
%         if ncam == 1
%             temporal_score = sigmoid(((227 - mean(x)) / 227), 0.95, 5) * this_score;
%         elseif ncam == 2
%             temporal_score = sigmoid((mean(x) / 227), 0.95, 5) * this_score;
%         end         
    else
        this_score = 0;
%         temporal_score = 0;
    end
    vis_pref_vals(2, ncam) = this_score;
%     vis_pref_vals(4, ncam) = temporal_score;
    

    % Blue
    blue = frame(:,:,3) > frame(:,:,2) * 1.5 & frame(:,:,3) > frame(:,:,1) * 1.5;
    blue(frame(:,:,3) < 50) = 0;
    
    blob = bwconncomp(blue);
    if blob.NumObjects
        [i, j] = max(cellfun(@numel,blob.PixelIdxList));
        npx = i;
        [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
        this_score = sigmoid(npx, 1000, 0.01) * 50;
%         if ncam == 1
%             temporal_score = sigmoid(((227 - mean(x)) / 227), 0.95, 5) * this_score;
%         elseif ncam == 2
%             temporal_score = sigmoid((mean(x) / 227), 0.95, 5) * this_score;
%         end        
    else
        this_score = 0;
%         temporal_score = 0;
    end
    vis_pref_vals(3, ncam) = this_score;
%     vis_pref_vals(6, ncam) = temporal_score;


    %% SVF
    this_array = sum(mean(uframe), 3);
    [max_val, this_score] = max(this_array);

    %% Left-max
    left_max = ((228 - this_score) / 227) * 50;
    left_max = (left_max^2)/50;
    vis_pref_vals(4, ncam) = left_max;
    %% Right-max
    right_max = (this_score / 227) * 50;
    right_max = (right_max^2)/50;
    vis_pref_vals(5, ncam) = right_max;
    %% Middle-max
    vis_pref_vals(6, ncam) = max_val * 0.01;

    vis_pref_vals;
    
    % Get object classification scores
    if use_cnn
        [label, score] = classify(g_net, frame);  
        cnn_out = sigmoid(score(object_ns), 0.04, 50);
        cnn_out = cnn_out - 0.15;
        cnn_out(cnn_out < 0) = 0;
        vis_pref_vals(7:n_vis_prefs, ncam) = cnn_out * 50;
    elseif use_rcnn
        try
            aitic = tic;
            
            [bbox, score, label] = detect(trainedDetector, frame, 'NumStrongestRegions', 500, 'threshold', 0, 'ExecutionEnvironment', 'gpu', 'MiniBatchSize', 128);
            [mscore, midx] = max(score);
            mbbox = bbox(midx, :);

            for nobject = 1:n_vis_prefs-6
                if ~isempty(max(score(label == object_strs{nobject})))
                    object_scores(nobject) = max(score(label == object_strs{nobject}));
                end
            end
            
            for nobject = 1:n_vis_prefs-6
                cnn_out = sigmoid(object_scores(nobject), 0.4, 40) * 50;
                vis_pref_vals(nobject + 6, ncam) = cnn_out;
            end
            
        catch
            disp('visual processing rcnn break')
        end
    end
    
end

