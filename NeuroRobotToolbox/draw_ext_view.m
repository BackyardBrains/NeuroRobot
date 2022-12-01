figure(16)
set(16, "Position", [300 150 404*2 227*2])
clf
ax1 = axes('position', [0.05 0.07 0.9 0.9]);

% trigger(ext_cam)
% this_frame = getdata(ext_cam, 1);
% this_frame = imresize(this_frame, [227 404]);
this_frame = zeros(227, 404, 3, 'uint8');

ext_im = image(this_frame);
hold on
robot_marker = plot(0, 0, 'marker', 'o', 'markersize', 50, 'color', 'w', 'linewidth', 3);
rblob_marker = plot(0, 0, 'marker', 'o', 'markersize', 25, 'color', 'r', 'linewidth', 2);
gblob_marker = plot(0, 0, 'marker', 'o', 'markersize', 25, 'color', 'g', 'linewidth', 2);
% set(ax1, 'xtick', [], 'ytick', [])
