fig_print = figure(4);
clf
set(fig_print, 'position', [120 360 1200 360]);
hold on
[y, x] = find(data.firing);
plot(x/10, y, 'linestyle', 'none', 'marker', '.', 'markersize', 15, 'color', 'k');
this_val = nneurons;
xlim([0 xstep/10])
ylim([0 this_val + 1])
set(gca, 'xtick', 0:round(xstep/50):xstep/10, 'ytick', 1:round(nneurons/5):nneurons, 'yticklabels', 1:round(nneurons/5):nneurons, 'fontsize', bfsize - 6, 'ydir', 'reverse', 'xcolor', 'k', 'ycolor', 'k', 'fontname', gui_font_name, 'fontweight', gui_font_weight)
ylabel('Neuron #')
box on
title('Neuronal activity')
xlabel('Time (seconds)')
set(gcf, 'color', 'w')

this_time = char(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss'));
export_fig(fig_print, horzcat('./Data/', this_time, '-', brain_name, '-activity_print'), '-r150', '-jpg', '-nocrop')



