function [ii, capture_now] = ground_truth_pulse_code(rak_cam, show_frame, capture_now, ii, frame_dir, fig_title)

ncam = 1;

try
    large_frame = rak_cam.readVideo();
%     large_frame = flip(permute(reshape(large_frame, 3, 1280, 720),[3,2,1]), 3);
    large_frame = permute(reshape(large_frame, 3, rak_cam.readVideoWidth(), rak_cam.readVideoHeight()),[3,2,1]);
catch
    disp('RAK fail')
end

frame = large_frame(1:720, 301:1020, :);
show_frame.CData = frame;
drawnow
1
% 
% frame = single(frame);
% frame = imresize(frame, [227 227]);
% 
% tic
% [bbox, score] = detect(rcnn, frame, 'NumStrongestRegions', 100, 'threshold', 0, 'ExecutionEnvironment', 'gpu');
% 
% if isempty(bbox)
%     score = 0;
% end
% if length(score) > 1
%     [score, idx] = max(score);
%     bbox = bbox(idx, :);
% end
% cnn_out = sigmoid(score, 0.55, 40) * 50;
% 
% if ~isempty(bbox)
%     if ncam == 1
%         this_val = ((227 - (bbox(1) + (bbox(3) / 2))) / 227);
%         temporal_cnn_out = cnn_out * sigmoid(this_val, 0.7, 5);
%     elseif ncam == 2
%         this_val = ((bbox(1) + (bbox(3) / 2)) / 227);
%         temporal_cnn_out = cnn_out * sigmoid(this_val, 0.7, 5);
%     end
% else
%     temporal_cnn_out = 0;
% end

if capture_now
    ii = ii + 1;
    if ii < 10
        id = strcat('000', num2str(ii));
    elseif ii < 100
        id = strcat('00', num2str(ii));
    elseif ii < 1000
        id = strcat('0', num2str(ii));
    else
        disp('too many images in directory')
    end
%     frame = large_frame(1:720, 301:1020, :);
%     frame = single(frame);
%     frame = imresize(frame, [227 227]);    
    imwrite(frame, horzcat(frame_dir, 'frame_', id, '.png'))
    disp(horzcat('Frame ', num2str(ii), ' captured'))
    capture_now = 0;
end

drawnow

% this_text = horzcat('npic = ', num2str(ii), ', score = ', num2str(round(score * 100)/100), ', cnn out = ', num2str(round(cnn_out)), ', temporal = ', num2str(round(temporal_cnn_out)), ', step time = ', num2str((round(toc * 1000) / 1000) * 1000), ' ms');
this_text = horzcat('picture number = ', num2str(ii));

disp(this_text)
fig_title.String = this_text;
