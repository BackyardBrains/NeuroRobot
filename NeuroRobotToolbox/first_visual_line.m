figure(5)
clf
this_frame = zeros(227, 404, 3, 'uint8');
bl_ax1 = axes('position', [0 0 1 1]);
bl_frame1 = image(this_frame);
hold on
bl1_scr = scatter([1 1 1], [1 1 1], 5, 'r');
bl1_scg = scatter([1 1 1], [1 1 1], 5, 'g');
bl1_scb = scatter([1 1 1], [1 1 1], 5, 'b');
set(gca, 'xtick', [], 'ytick', [])

% bl_ax2 = axes('position', [0.1 0.85 0.8 0.05]);
% bl_plot1 = plot(1,1,'r', 'marker', '.', 'markersize', 30);
% hold on
% bl_plot2 = plot(1,1,'color',[0 0.7 0], 'marker', '.', 'markersize', 30);
% bl_plot3 = plot(1,1,'color','b', 'marker', '.', 'markersize', 30);
% xlim([1 404])
% ylim([0 50])
