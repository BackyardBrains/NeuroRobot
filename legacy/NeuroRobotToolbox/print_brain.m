

im3 = flipud(255 - ((255 - imread('workspace.jpg'))));

fig_print = figure(3);
set(fig_print, 'position', [400 100 1000 800]);
brain_axb = axes('position', [0 0 1 1]);
image('CData',im3,'XData',[-3 3],'YData',[-3 3])
set(brain_axb, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
axis([-3 3 -3 3])
hold on
draw_brain
this_time = char(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss'));

export_fig(fig_print, horzcat(this_time, '-', brain_name, '-brain_print'), '-r150', '-jpg', '-nocrop')

close(fig_print)