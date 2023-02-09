
nstep = nstep + 1;

trigger(cam)
frame = getdata(cam, 1); 
uframe = imresize(frame, net_input_size);

xframe = imsubtract(rgb2gray(uframe), rgb2gray(prev_uframe));
bwframe = xframe > 10;  
blob = bwconncomp(bwframe);
if blob.NumObjects
    [npx, this_blob] = max(cellfun(@numel,blob.PixelIdxList));
    [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{this_blob});
    robot_xy = [mean(x), mean(y)];
else
    robot_xy = [0 0];
end

prev_uframe = uframe;

draw_im.CData = uframe;
% draw_im.CData = xframe;
draw_xy.XData = robot_xy(1);
draw_xy.YData = robot_xy(2);
title_obj.String = horzcat('Frame: ', num2str(nstep));

%% Save xy to disk (align to spikerbot camera frames later)
save('robot_xy', 'robot_xy', '-mat')

%% Check for stop
if flag && exist('ext_runtime_pulse','var')
    stop(ext_runtime_pulse)
    delete(ext_runtime_pulse)
end
