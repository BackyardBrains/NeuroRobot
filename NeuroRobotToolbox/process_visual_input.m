
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


    % Run custom r-cnn net
    if use_rcnn
        [bbox, score, label] = detect(rcnn, uframe, 'NumStrongestRegions', 500, 'MiniBatchSize',128);
        
        this_score = max(score);
        if isempty(this_score)
            this_score = 0;
        end
        disp(horzcat('p(robot) = ', num2str(this_score)));
        this_score = sigmoid(this_score, 0.99, 100);
        
        if ~use_cnn
            vis_pref_vals(8, ncam) = this_score * 50;
        else
            vis_pref_vals(21, ncam) = this_score * 50;
        end
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


% XYO Net
if use_xyo_net || sum(neuron_scripts == 6)

    % %% Subjective xyo
    % lframe = imresize(large_frame, [net_input_size(1) net_input_size(2)]);
    % xyo = predict(xyoNet, double(lframe));
    % % disp(horzcat('x: ', num2str(xyo(1)), ', y: ', num2str(xyo(2)), ', o:', num2str(xyo(3))))
    % 
    % this_x = xyo(1);
    % this_y = xyo(2);
    % this_o = xyo(3);

    %% Objective xyo
    robot_xy = ext_data.robot_xy;
    rblob_xy = ext_data.rblob_xy;
    gblob_xy = ext_data.gblob_xy;

    this_x = robot_xy(1);
    this_y = robot_xy(2);

    x1 = rblob_xy(1);
    y1 = rblob_xy(2);
    x2 = gblob_xy(1);
    y2 = gblob_xy(2);

    sepx = x1-x2;
    sepy = y1-y2;

    this_o = mod(atan2d(sepy,sepx),360); 


    %% Get xyo state    
    if use_xyo_net

        xyo_state = get_xyo_state(this_x, this_y, this_o, xlims, ylims, n_unique_states);
        
        % Synaptic adjust
        vis_pref_vals(7 + 1 : end, 1) = 0;
        vis_pref_vals(7 + 1 : end, 2) = 0;
    
        vis_pref_vals(7 + xyo_state, 1) = 50;
        vis_pref_vals(7 + xyo_state, 2) = 50;
    end
    
elseif use_custom_net

    lframe = imresize(large_frame, [net_input_size(1) net_input_size(2)]);
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
