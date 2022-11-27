figure(16)
set(16, "Position", [300 150 404*2 227*2])
clf
ax1 = axes('position', [0.05 0.07 0.9 0.9]);
ext_im = image(zeros(227, 404, 3, 'uint8'));
hold on
ext_xy = plot(0, 0, 'marker', 'o', 'markersize', 50, 'color', [1 0.5 0], 'linewidth', 3);
% set(ax1, 'xtick', [], 'ytick', [])
ext_im.CData = ext_uframe;
ext_xy.XData = robot_xy(1);
ext_xy.YData = robot_xy(2);