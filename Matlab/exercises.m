

% Brain Exercises
%%%%%%%%%%%%%%%%%
% Selection interface


%% Prepare figure
fig_game = figure(5);
clf
set(fig_game, 'NumberTitle', 'off', 'Name', 'Brain Game')
set(fig_game, 'menubar', 'none', 'toolbar', 'none')
set(fig_game, 'position', fig_pos, 'color', 'w') 


%% Draw brains
total_pos = [0.16 0.04 0.78 0.9];
n = 0;
while n^2 < nbrains - 1
    n = n + 1;
end
% xb = (total_pos(3) / n) - (0.02 * (n - 1));
xb = total_pos(3) - (0.01 * (n - 1));
xb = xb / n;
% yb = (total_pos(4) / n) - (0.02 * (n - 1));
yb = total_pos(4) - (0.01 * (n - 1));
yb = yb / n;
brain_ax_pos = [];
nbrain = 0;
for jj = 1:n
    for ii = 1:n  
        if nbrain <= nbrains - 1
            nbrain = nbrain + 1;

            brain_name = popup_select_brain.String{nbrain + 1};
            load_name = brain_name;
            brain_selection_val = 2; % Needed
            load_or_initialize_brain

            brain_ax_pos = [total_pos(1) + ((ii-1) * (xb + 0.01)), total_pos(2) + total_pos(4) - (jj * (yb + 0.01)) + 0.01, xb, yb];
            brain_multiax(nbrain).ax = axes('position', brain_ax_pos);
            im3 = flipud(255 - ((255 - imread('workspace.jpg'))));
            image('CData',im3,'XData',[-3 3],'YData',[-3 3])
            box on
            set(brain_multiax(nbrain).ax, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
            hold on
            draw_brain
            axis([-3.1 5.4 -3.3 4.2])
            ax_frame = getframe(brain_multiax(nbrain).ax);
            delete(brain_multiax(nbrain).ax)
            
            brain_ax_pos = [total_pos(1) + ((ii-1) * (xb + 0.01)), total_pos(2) + total_pos(4) - (jj * (yb + 0.01)) + 0.01, xb, yb];
            brain_multiax(nbrain).ax = axes('position', brain_ax_pos);
            image(ax_frame.cdata)
            set(brain_multiax(nbrain).ax, 'xtick', [], 'ytick', [])
            hold on
            text(120, 13, brain_name, 'FontName', gui_font_name, 'fontsize', 12, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'FontWeight', 'bold');            
            
        end
    end
end
