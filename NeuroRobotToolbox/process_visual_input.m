
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
    else
        this_score = 0;
    end

    vis_pref_vals(7, ncam) = this_score;
    
    % Get complex features
%     if use_custom_net % Lets stop doing this
%         imdim = 100;
%         frame = imresize(frame, [imdim imdim]);
%     end
    if use_cnn || use_custom_net
        if ~regress
            [~, scores] = classify(net, frame);
        elseif ncam == 1
            scores = predict(net, frame);
            disp(horzcat('Theta = ', num2str(scores)))
            scores = scores / 360;
        end
        if use_cnn
            scores = scores(object_ns);
        end
%         scores = scores / max([scores, 0.2]);
%         scores = scores / max([scores, 0.2]);
%         scores = sigmoid(scores, 0.6, 50) * 50;
        vis_pref_vals(8:n_vis_prefs, ncam) = scores * 50;
    end
    
    if ncam == 1
        prev_left_eye_frame = uframe;
    elseif ncam == 2
        prev_right_eye_frame = uframe;
    end

%     if ncam == 1
%         disp(num2str(vis_pref_vals(7 + [3 10], 1)'))
%         disp('----')
%     end

end
