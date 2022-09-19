


%%tbd
error('not implemented')

% Brain display
brain_ax = axes('position', [0.475 0.16 0.45 0.69]);
image('CData',im2,'XData',[-3 3],'YData',[-3 3])
set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col)
axis([-3 3 -3 3])
hold on
box off
ext_ax = brain_ax;


% update_brain_name_edit
% draw_brain  ???
