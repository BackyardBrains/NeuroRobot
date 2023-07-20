

draw_ext1.CData = ext_frame;

xframe = imsubtract(rgb2gray(ext_frame), rgb2gray(prev_ext_frame));

ext_blob = bwconncomp(bwframe > 100);
if ext_blob.NumObjects
    [npx, this_blob] = max(cellfun(@numel,ext_blob.PixelIdxList));
    [blob_y, blob_x] = ind2sub(ext_blob.ImageSize, ext_blob.PixelIdxList{this_blob});
    robot_xy = round([mean(blob_x), mean(blob_y)]);
end


draw_ext1b.XData = robot_xy(1);
draw_ext1b.YData = robot_xy(2);


padding = 40;
xx = max([robot_xy(1) padding]);
xx = min([xx ext_cam_w - padding]);
yy = max([robot_xy(2) padding]);
yy = min([yy ext_cam_h - padding]);

xpadding = padding-1;
ext_frame_zoom = ext_frame(yy-xpadding:yy+xpadding,xx-xpadding:xx+xpadding,:);


draw_ext2.CData = ext_frame_zoom;

% robot_xy = [0 0];
rblob_xy = [0 0];
gblob_xy = [0 0];

prev_ext_frame = ext_frame;
