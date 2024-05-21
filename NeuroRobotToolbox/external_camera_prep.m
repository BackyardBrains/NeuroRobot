
% run this after connenct camera but before runtime
% dock it
ext_cam_h = 480;
ext_cam_w = 640;

ext_frame = zeros(ext_cam_h, ext_cam_w, 3, 'uint8');
robot_xy = [300 244];

figure(21)
clf

subplot(2,1,1)

draw_ext = image(ext_frame);
hold on
robot_marker = plot(0, 0, 'marker', 'o', 'markersize', 50, 'color', 'k', 'linewidth', 3);

padding = 100;
xx = max([robot_xy(1) padding]);
xx = min([xx ext_cam_w - padding]);
yy = max([robot_xy(2) padding]);
yy = min([yy ext_cam_h - padding]);

xpadding = padding-1;
ext_frame_zoom = ext_frame(yy-xpadding:yy+xpadding,xx-xpadding:xx+xpadding,:);

subplot(2,1,2)
draw_ext_zoom = image(ext_frame_zoom);
hold on
rblob_marker = plot(0, 0, 'marker', 'o', 'markersize', 25, 'color', 'b', 'linewidth', 2);
gblob_marker = plot(0, 0, 'marker', 'o', 'markersize', 25, 'color', 'g', 'linewidth', 2);
this_ext_str = 'x: y: o: s: ';
ext_title = title(this_ext_str);

