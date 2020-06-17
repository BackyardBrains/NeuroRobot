

s = [10 20 30 40 50 60 70 100 150 200 300 400 500];
a = [51 61 76 104 NaN NaN NaN NaN NaN NaN NaN NaN NaN];
b = [49 50 53 55 56 56 56 62 63 64 70 80 96];

figure(1)
clf
set(gcf, 'position', [2560 480 340 230], 'color', 'w')
plot(a, s, 'linestyle', '-.', 'markersize', 20, 'marker', '.')
hold on
plot(b, s, 'linestyle', '-.', 'markersize', 20, 'marker', '.')
plot([100 100], [0 300], 'linestyle', '--', 'color', 'r')
ylim([0 580])
box off

ylabel('Number of neurons', 'FontName', 'Comic Book')
xlabel('Step time (ms)', 'FontName', 'Comic Book')

legend('Axons drawn', 'Axons not drawn', 'location', 'northwest', 'FontName', 'Comic Book', 'box', 'off')
title('How many neurons can I simulate?', 'FontName', 'Comic Book', 'fontsize', 12)

export_fig(gcf, 'nneurons', '-r150', '-jpg', '-nocrop')