figure(16)
ax1 = axes('position', [0 0.05 1 0.9]);
ext_im = image(ext_uframe);
hold on
ext_xy = plot(robot_xy(1), robot_xy(2), 'marker', '.', 'markersize', 20, 'color', 'r');
set(ax1, 'xtick', [], 'ytick', [])

ext_im.CData = ext_uframe;
ext_xy.XData = robot_xy(1);
ext_xy.YData = robot_xy(2);