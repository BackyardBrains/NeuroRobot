brain_ax_pos = [0.27 0.25 0.46 0.73];
brain_ax = axes('position', brain_ax_pos);
image('CData',im,'XData',[-3 3],'YData',[-3 3])
set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col)
axis([-3 3 -3 3])
hold on 