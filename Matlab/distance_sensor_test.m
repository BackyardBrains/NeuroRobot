figure(1)
clf
set(gcf, 'position', [420 420 640 420], 'color', 'w')
h1 = plot(sigmoid(0:4000, 1000, -0.8) * 50, 'linewidth', 2);
hold on
h2 = plot(sigmoid(0:4000, 2000, -0.8) * 50, 'linewidth', 2);
h3 = plot(sigmoid(0:4000, 3000, -0.8) * 50, 'linewidth', 2);
legend('Short (1m)', 'Medium (2m)', 'Long (3m)')
xlabel('Distance (mm)')
ylabel('Input voltage (mV)')
xlim([0 4000])
ylim([0 70])
title('Distance Preferences for Neurons')