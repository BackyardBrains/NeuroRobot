function [ii, capture_now] = ground_truth_pulse_code(rak_cam, show_frame, capture_now, ii, frame_dir)

try
    large_frame = rak_cam.readVideo();
    large_frame = flip(permute(reshape(large_frame, 3, 1280, 720),[3,2,1]), 3);
catch
    disp('RAK fail')
end

frame = large_frame(1:720, 301:1020, :);
show_frame.CData = frame;
frame = imresize(frame, [224 224]);

if capture_now
    ii = ii + 1;
    if ii < 10
        id = strcat('000', num2str(ii));
    elseif ii < 10
        id = strcat('00', num2str(ii));
    elseif ii < 1000
        id = strcat('0', num2str(ii));
    else
        id = num2str(ii);
    end
    imwrite(frame, horzcat(frame_dir, 'frame_', id, '.png'))
    disp(horzcat('Frame ', num2str(ii), ' captured'))
    capture_now = 0;
end
