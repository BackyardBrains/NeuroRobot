total_pos = [0.27 0.25 0.46 0.73];
n = 0;
while n^2 < nnetworks
    n = n + 1;
end
% xb = (total_pos(3) / n) - (0.02 * (n - 1));
xb = total_pos(3) - (0.02 * (n - 1));
xb = xb / n;
% yb = (total_pos(4) / n) - (0.02 * (n - 1));
yb = total_pos(4) - (0.02 * (n - 1));
yb = yb / n;
brain_ax_pos = [];
nnetwork = 0;
for jj = 1:n
    for ii = 1:n
        nnetwork = nnetwork + 1;
        brain_ax_pos = [total_pos(1) + ((ii-1) * (xb + 0.02)), total_pos(2) + total_pos(4) - (jj * (yb + 0.02)) + 0.02, xb, yb];
        brain_multiax(nnetwork).ax = axes('position', brain_ax_pos);
        image('CData',im,'XData',[-3 3],'YData',[-3 3])
        set(brain_multiax(nnetwork).ax, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col)
        axis([-3 3 -3 3])
        hold on            
        % initalize axes width thing here
    end
end
