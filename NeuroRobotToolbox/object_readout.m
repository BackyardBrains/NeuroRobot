figure;
lrrr = bar(score(object_ns));
hold on
plot(xlim, [0.2 0.2], 'color', [0.75 0 0], 'linestyle', '--')
set(gca, 'xticklabels', object_strs)
ylim([0 0.3])
