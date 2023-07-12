
for ncam = 1:2

    if ncam == 1
        uframe = imresize(left_eye_frame, net_input_size);
        left_uframe = uframe;
        frame = single(uframe);
        xframe = imsubtract(rgb2gray(uframe), rgb2gray(prev_left_eye_frame));
    else
        uframe = imresize(right_eye_frame, net_input_size);
        right_uframe = uframe;
        frame = single(uframe);
        xframe = imsubtract(rgb2gray(uframe), rgb2gray(prev_right_eye_frame));
    end

    for ncol = 1:3
        if ncol == 1
            colframe = uframe(:,:,1) > uframe(:,:,2) * 1.5 & uframe(:,:,1) > uframe(:,:,3) * 1.5;
            colframe(uframe(:,:,1) < 50) = 0;
        elseif ncol == 2
            colframe = uframe(:,:,2) > uframe(:,:,1) * 1.3 & uframe(:,:,2) > uframe(:,:,3) * 1.3;
            colframe(uframe(:,:,2) < 50) = 0;
        elseif ncol == 3     
            colframe = uframe(:,:,3) > uframe(:,:,2) * 1.2 & uframe(:,:,3) > uframe(:,:,1) * 1.2;
            colframe(uframe(:,:,3) < 50) = 0;
        end
    
        blob = bwconncomp(colframe);
        if blob.NumObjects
            [i, j] = max(cellfun(@numel,blob.PixelIdxList));
            npx = i;
            [~, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
            this_score = sigmoid(npx, 1000, 0.0075) * 50;
            this_left_score = sigmoid(((228 - mean(x)) / 227), 0.85, 10) * this_score;
            this_right_score = sigmoid(((mean(x)) / 227), 0.85, 10) * this_score;
        else
            x = 0;
            this_score = 0;
            this_left_score = 0;
            this_right_score = 0;
        end

        vis_pref_vals(ncol * 2 - 1, ncam) = this_score;
        if ncam == 1
            vis_pref_vals(ncol * 2, ncam) = this_left_score;
        else
            vis_pref_vals(ncol * 2, ncam) = this_right_score;
        end

    end

    bwframe = xframe > 20;
    
    blob = bwconncomp(bwframe);
    if blob.NumObjects
        [i, j] = max(cellfun(@numel,blob.PixelIdxList));
        npx = i;
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

    vis_pref_vals(7, ncam) = this_score;
    
    % Get complex features
    if use_cnn
        [label, score] = classify(g_net, frame);  
        [i, j] = max(score);
        cnn_out = sigmoid(i, 0.6, 50);
        cnn_out(cnn_out < 0) = 0;
        cnn_out = cnn_out * 50;
%         if ncam == 1
%             disp(horzcat('Score: ', num2str(i), ', cnn out: ', num2str(cnn_out), ', ncam = ', num2str(ncam)))
%         end
        vis_pref_vals(8:n_vis_prefs, ncam) = cnn_out;
    elseif use_rcnn
        try
            aitic = tic;
            
            [bbox, score, label] = detect(trainedDetector, frame, ...
                'NumStrongestRegions', 500, 'threshold', 0, ...
                'ExecutionEnvironment', 'gpu', 'MiniBatchSize', 128);
            [mscore, midx] = max(score);
            mbbox = bbox(midx, :);

            for nobject = 1:n_vis_prefs-n_basic_vis_features
                if ~isempty(max(score(label == object_strs{nobject})))
                    object_scores(nobject) = max(score(label == object_strs{nobject}));
                end
            end
            
            for nobject = 1:n_vis_prefs-n_basic_vis_features
                cnn_out = sigmoid(object_scores(nobject), 0.5, 40) * 50;
                vis_pref_vals(nobject + n_basic_vis_features, ncam) = cnn_out;
            end
            
        catch
            disp('visual processing rcnn break')
        end
    elseif use_controllers
        if ncam == 1
            imdim = 100;
            left_uframe = imresize(left_uframe, [imdim imdim]);
            [left_state, left_score] = classify(net, left_uframe);
            left_state = find(unique_states == left_state);
            left_score = left_score(left_state);
            for nobject = n_basic_vis_features + 1:n_vis_prefs
                if nobject - n_basic_vis_features == left_state && left_score > 0.25
                    vis_pref_vals(nobject, ncam) = 50 * left_score;
                else
                    vis_pref_vals(nobject, ncam) = 0;
                end
            end
        elseif ncam == 2
            imdim = 100;
            right_uframe = imresize(right_uframe, [imdim imdim]);
            [right_state, right_score] = classify(net, right_uframe);
            right_state = find(unique_states == right_state);
            right_score = right_score(right_state);
            for nobject = n_basic_vis_features + 1:n_vis_prefs
                if nobject - n_basic_vis_features == right_state && right_score > 0.25
                    vis_pref_vals(nobject, ncam) = 50 * right_score;
                else
                    vis_pref_vals(nobject, ncam) = 0;
                end
            end
        end
%         disp(horzcat('Left state: ', num2str(left_state), ', Right state: ', num2str(right_state)))
%         disp(horzcat('Left score: ', num2str(left_score), ', Right score: ', num2str(right_score)))
    end
    
    if ncam == 1
        prev_left_eye_frame = uframe;
    elseif ncam == 2
        prev_right_eye_frame = uframe;
    end

%     if ncam == 1
%         disp(num2str(vis_pref_vals([1 3 5], 1)'))
%         disp('----')
%     end

end
