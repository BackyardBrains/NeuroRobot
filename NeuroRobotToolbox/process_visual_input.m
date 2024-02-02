
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
            this_score = sigmoid(npx, 200, 0.05) * 50;
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
    
    % Run pretrained object detector googlenet
    if use_cnn
        [~, scores] = classify(gnet, frame);
        cup_score = max(scores([505 739 969]));
        scores = scores(object_ns);
        scores(4) = cup_score;
        vis_pref_vals(8:8+12, ncam) = scores * 50;
    end


    %% Step
    if ncam == 1
        prev_left_eye_frame = uframe;
    elseif ncam == 2
        prev_right_eye_frame = uframe;
    end

end

if use_esp32 && use_webcam
    external_camera
end

% Run custom r-cnn net
if use_rcnn

    [bbox, score, label] = detect(rcnn, large_frame);
    % , 'threshold', 0, 'ExecutionEnvironment', 'gpu');
    
    cone_inds = find(label == 'cone');
    robot_inds = find(label == 'robot');

    if ~isempty(cone_inds)
        cone_score = max(score(cone_inds));
    else
        cone_score = 0;
    end

    if ~isempty(robot_inds)
        robot_score = max(score(robot_inds));
    else
        robot_score = 0;        
    end

    disp(horzcat('cone: ', num2str(cone_score), ', robot: ', num2str(robot_score)))

    if ~use_cnn
        vis_pref_vals(8:8+1, 1) = [cone_score robot_score] * 50;
        vis_pref_vals(8:8+1, 2) = [cone_score robot_score] * 50;
    else
        vis_pref_vals(12:12+1, 1) = [cone_score robot_score] * 50;
        vis_pref_vals(12:12+1, 2) = [cone_score robot_score] * 50;
    end

    % [mscore, midx] = max(score);
    % mbbox = bbox(midx, :);
    % mlabel = char(label(midx));
    % 
    % qi = 0.5;
    % x = bbox(score > qi,1) + bbox(score > qi,3)/2;
    % y = bbox(score > qi,2) + bbox(score > qi,4)/2;
    % mx = mbbox(:,1) + mbbox(:,3)/2;
    % my = mbbox(:,2) + mbbox(:,4)/2;
    % 
    % nboxes = length(x);

end

% Lesson 3 nets
if use_custom_net
    lframe = imresize(large_frame, [227 302]);
    [~, scores] = classify(net, lframe);
    
    [i, j] = max(scores);
    inds = 1:n_unique_states;
    inds(j) = [];
    scores(inds) = 0;

    if ~use_cnn % Needs rcnn fix
        vis_pref_vals(8:end, 1) = scores * 50;
        vis_pref_vals(8:end, 2) = scores * 50;
    else
        vis_pref_vals(8+13:end, 1) = scores * 50;
        vis_pref_vals(8+13:end, 2) = scores * 50;
    end    
end
