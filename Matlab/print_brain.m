fig_print = figure(3);
set(fig_print, 'position', [400 100 1000 800]);
brain_ax = axes('position', [0 0 1 1]);
image('CData',im2,'XData',[-3 3],'YData',[-3 3])
set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
axis([-3 3 -3 3])
hold on
draw_brain
this_time = char(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss'));
export_fig(fig_print, horzcat('.\Data\', this_time, '-', brain_name, '-brain_print'), '-r150', '-jpg', '-nocrop')
