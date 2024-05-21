

draw_ext.CData = ext_frame;

xframe = imsubtract(rgb2gray(ext_frame), rgb2gray(prev_ext_frame));
bwframe = xframe > 50;

ext_blob = bwconncomp(bwframe);
if ext_blob.NumObjects
    [npx, this_blob] = max(cellfun(@numel,ext_blob.PixelIdxList));
    [blob_y, blob_x] = ind2sub(ext_blob.ImageSize, ext_blob.PixelIdxList{this_blob});
    robot_xy = round([mean(blob_x), mean(blob_y)]);
end

robot_marker.XData = robot_xy(1);
robot_marker.YData = robot_xy(2);

padding = 100;
xx = max([robot_xy(1) padding]);
xx = min([xx ext_cam_w - padding]);
yy = max([robot_xy(2) padding]);
yy = min([yy ext_cam_h - padding]);

xpadding = padding-1;
ext_frame_zoom = ext_frame(yy-xpadding:yy+xpadding,xx-xpadding:xx+xpadding,:);

draw_ext_zoom.CData = ext_frame_zoom;

% red
% colframe = ext_frame_zoom(:,:,1) > ext_frame_zoom(:,:,2) * 1.5 & ext_frame_zoom(:,:,1) > ext_frame_zoom(:,:,3) * 1.5;
% colframe(ext_frame_zoom(:,:,1) < 75) = 0;
% rblob = bwconncomp(colframe);

% red but actually blue
colframe = ext_frame_zoom(:,:,3) > ext_frame_zoom(:,:,2) * 1.2 & ext_frame_zoom(:,:,3) > ext_frame_zoom(:,:,1) * 1.2;
colframe(ext_frame_zoom(:,:,3) < 50) = 0;
rblob = bwconncomp(colframe);

% green
colframe = ext_frame_zoom(:,:,2) > ext_frame_zoom(:,:,1) * 1.3 & ext_frame_zoom(:,:,2) > ext_frame_zoom(:,:,3) * 1.3;
colframe(ext_frame_zoom(:,:,2) < 75) = 0;
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

draw_ext_zoom.CData = ext_frame_zoom;
robot_marker.XData = robot_xy(1);
robot_marker.YData = robot_xy(2);

rblob_marker.XData = rblob_xy(1);
rblob_marker.YData = rblob_xy(2);
gblob_marker.XData = gblob_xy(1);
gblob_marker.YData = gblob_xy(2);

% rblob_marker.XData = rblob_xy(1) + xx - padding;
% rblob_marker.YData = rblob_xy(2) + yy - padding;
% gblob_marker.XData = gblob_xy(1) + xx - padding;
% gblob_marker.YData = gblob_xy(2) + yy - padding;

prev_ext_frame = ext_frame;

