
% I2 = illumgray(large_frame, 5);

for ncam = 1:2

    if ncam == 1
        frame = single(left_eye_frame);
    else
        frame = single(right_eye_frame);
    end
    
    frame = imresize(frame, net_input_size);

%     if sum(I2)
%         frame = chromadapt(frame, I2, 'ColorSpace', 'linear-rgb');
%         frame = lin2rgb(frame);    
%     end

    % Red
    red = frame(:,:,1) > frame(:,:,2) * 2 & frame(:,:,1) > frame(:,:,3) * 2;
    red(frame(:,:,1) < 50) = 0;
    
    blob = bwconncomp(red);
    if blob.NumObjects
        [i, j] = max(cellfun(@numel,blob.PixelIdxList));
        npx = i;
        [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
        this_score = sigmoid(npx, 1000, 0.01) * 50;
        if ncam == 1
            temporal_score = sigmoid(((227 - mean(x)) / 227), 0.95, 5) * this_score;
%             temporal_score = ((227 - mean(x)) / 227) * this_score;
        elseif ncam == 2
            temporal_score = sigmoid((mean(x) / 227), 0.95, 5) * this_score;
%             temporal_score = (mean(x) / 227) * this_score;
        end        
    else
        this_score = 0;
        temporal_score = 0;
    end
    vis_pref_vals(1, ncam) = this_score;
    vis_pref_vals(2, ncam) = temporal_score;
    
    % Green
    green = frame(:,:,2) > frame(:,:,1) * 1.2 & frame(:,:,2) > frame(:,:,3) * 1.2;
    green(frame(:,:,2) < 50) = 0;
    
    blob = bwconncomp(green);
    if blob.NumObjects
        [i, j] = max(cellfun(@numel,blob.PixelIdxList));
        npx = i;
        [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
        this_score = sigmoid(npx, 1000, 0.01) * 50;
        if ncam == 1
            temporal_score = sigmoid(((227 - mean(x)) / 227), 0.95, 5) * this_score;
        elseif ncam == 2
            temporal_score = sigmoid((mean(x) / 227), 0.95, 5) * this_score;
        end         
    else
        this_score = 0;
        temporal_score = 0;
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
        this_score = sigmoid(npx, 1000, 0.01) * 50;
        if ncam == 1
            temporal_score = sigmoid(((227 - mean(x)) / 227), 0.95, 5) * this_score;
        elseif ncam == 2
            temporal_score = sigmoid((mean(x) / 227), 0.95, 5) * this_score;
        end        
    else
        this_score = 0;
        temporal_score = 0;
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
            aitic = tic;
%             [bbox, score] = detect(rcnn, frame, 'NumStrongestRegions', 100, 'MiniBatchSize', 32, 'ExecutionEnvironment', 'gpu');
            [bbox, score] = detect(rcnn, frame, 'NumStrongestRegions', 100, 'threshold', 0, 'ExecutionEnvironment', 'gpu');
            if isempty(bbox)
                score = 0;
            end
            if length(score) > 1
                [score, idx] = max(score);
                bbox = bbox(idx, :);
            end
            cnn_out = sigmoid(score, 0.55, 40) * 50;
            vis_pref_vals(7, ncam) = cnn_out;
            
            if ~isempty(bbox)
                if ncam == 1
                    this_val = ((227 - (bbox(1) + (bbox(3) / 2))) / 227);
                    temporal_cnn_out = cnn_out * sigmoid(this_val, 0.7, 5);
                elseif ncam == 2
                    this_val = ((bbox(1) + (bbox(3) / 2)) / 227);
                    temporal_cnn_out = cnn_out * sigmoid(this_val, 0.7, 5);
                end
            else
                temporal_cnn_out = 0;
                bbox = [0 0 0 0];
            end
            vis_pref_vals(8, ncam) = temporal_cnn_out;
            
            vis_pref_vals(9, ncam) = cnn_out * ((bbox(3) * bbox(4)) > 11000);
            this_text = horzcat('score = ', num2str(round(score * 100)/100), ', cnn out = ', num2str(round(cnn_out)), ', temporal = ', num2str(round(temporal_cnn_out)), ', step time = ', num2str(round(toc(aitic) * 1000)), ' ms');
        catch
            disp('process visual input break')
        end
    end
    
end

