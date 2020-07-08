figure
set(gcf, 'position', [200 400 855 277], 'color', 'w')
plot(mean_activity, 'color', [0.2 0.4 0.8], 'linewidth', 2)
hold on
plot(intended_activity, 'color', [0.8 0.4 0.2], 'linewidth', 2)
ylim([0 1.3])
legend('Actual network behavior', 'Intended network behavior')
title(horzcat('Actual vs intended network behavior, error = ', num2str(this_error)))
xlabel('Time')
