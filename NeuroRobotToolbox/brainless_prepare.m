
left_cut = [1 rak_cam_h 1 rak_cam_h]; 
right_cut = [1 rak_cam_h (rak_cam_w - rak_cam_h + 1) rak_cam_w];    
left_yx = [length(left_cut(1):left_cut(2)) length(left_cut(3):left_cut(4))];
right_yx = [length(right_cut(1):right_cut(2)) length(right_cut(3):right_cut(4))];

figure(5)
clf
set(gcf, 'position', [220 250 830 520])
bl1_plt = bar(zeros(nfeatures * nsensors, 1));
ylim([0 0.5])
title('feature vector')

% this_frame = zeros(227, 404, 3, 'uint8');
% prev_frame = zeros(227, 404, 3, 'uint8');
% bl_ax1 = axes('position', [0 0 1 1]);
% bl_frame1 = image(this_frame);
% hold on
% bl1_scr = scatter([1 1 1], [1 1 1], 5, 'r');
% bl1_scg = scatter([1 1 1], [1 1 1], 5, 'g');
% bl1_scb = scatter([1 1 1], [1 1 1], 5, 'b');
% bl1_scbri = scatter([1 1 1], [1 1 1], 2, 'white', 'filled');

% set(gca, 'xtick', [], 'ytick', [])

% warning('off','all')

% bl_ax2 = axes('position', [0.1 0.85 0.8 0.05]);
% bl_plot1 = plot(1,1,'r', 'marker', '.', 'markersize', 30);
% hold on
% bl_plot2 = plot(1,1,'color',[0 0.7 0], 'marker', '.', 'markersize', 30);
% bl_plot3 = plot(1,1,'color','b', 'marker', '.', 'markersize', 30);
% xlim([1 404])

