
trigger(ext_cam)
ext_frame = getdata(ext_cam, 1); %%% <<<<< Commented out for packaging        
ext_uframe = imresize(ext_frame, [227 404]);
ext_im.CData = ext_uframe;

ext_xframe = imsubtract(rgb2gray(ext_uframe), rgb2gray(prev_ext_uframe));
ext_bwframe = ext_xframe > 125;  
ext_blob = bwconncomp(ext_bwframe);
if ext_blob.NumObjects
    [npx, this_blob] = max(cellfun(@numel,ext_blob.PixelIdxList));
    [blob_y, blob_x] = ind2sub(ext_blob.ImageSize, ext_blob.PixelIdxList{this_blob});
    robot_xy = [mean(blob_x), mean(blob_y)];
end
robot_xy = round(robot_xy);
prev_ext_uframe = ext_uframe;

padding = 30;
xx = max([robot_xy(1) padding]);
xx = min([xx 404 - padding]);
yy = max([robot_xy(2) padding]);
yy = min([yy 227 - padding]);

xpadding = padding-1;
uframe = ext_uframe(yy-xpadding:yy+xpadding,xx-xpadding:xx+xpadding,:);

colframe = uframe(:,:,1) > uframe(:,:,2) * 1.5 & uframe(:,:,1) > uframe(:,:,3) * 1.5;
colframe(uframe(:,:,1) < 75) = 0;
rblob = bwconncomp(colframe);

colframe = uframe(:,:,2) > uframe(:,:,1) * 1.3 & uframe(:,:,2) > uframe(:,:,3) * 1.3;
colframe(uframe(:,:,2) < 75) = 0;
gblob = bwconncomp(colframe);

if rblob.NumObjects
    [npx, this_blob] = max(cellfun(@numel,rblob.PixelIdxList));
    [blob_y, blob_x] = ind2sub(rblob.ImageSize, rblob.PixelIdxList{this_blob});
    rblob_xy = [mean(blob_x), mean(blob_y)];
end
rblob_xy = round(rblob_xy);

if gblob.NumObjects
    [npx, this_blob] = max(cellfun(@numel,gblob.PixelIdxList));
    [blob_y, blob_x] = ind2sub(gblob.ImageSize, gblob.PixelIdxList{this_blob});
    gblob_xy = [mean(blob_x), mean(blob_y)];
end
gblob_xy = round(gblob_xy);

ext_data.robot_xy = robot_xy;
ext_data.rblob_xy = rblob_xy;
ext_data.gblob_xy = gblob_xy;

fname = strcat(rec_dir_name_2, computer_name, '-', user_name, '-', this_time, '-', brain_name, '-', num2str(xstep), '-robot_xy.mat');        
save(fname, 'ext_data', '-mat');

ext_im.CData = ext_uframe;
robot_marker.XData = robot_xy(1);
robot_marker.YData = robot_xy(2);
rblob_marker.XData = rblob_xy(1) + xx - padding;
rblob_marker.YData = rblob_xy(2) + yy - padding;
gblob_marker.XData = gblob_xy(1) + xx - padding;
gblob_marker.YData = gblob_xy(2) + yy - padding;
