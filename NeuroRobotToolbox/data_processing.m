

% data holds min and max timestep duration at nneurons
clear data
% data(1, :) = [64 75 1000]; % acer
% data(2, :) = [67 73 1100]; % acer
% data(3, :) = [72 79 1200]; % acer
% data(4, :) = [80 86 1300]; % acer
% data(5, :) = [86 96 1400]; % acer
% data(6, :) = [106 117 1500]; % acer


data(1, :) = [81 1200]; % acer
data(2, :) = [83 1300]; % acer
data(3, :) = [90 1400]; % acer
data(4, :) = [98 1500]; % acer


clf
set(gcf, 'color', 'w')
plot(data(:, 1), '-.', 'marker', '.', 'markersize', 20)
hold on
plot([1 length(data)], [100 100], 'linestyle', '--', 'color', 'k')
ylim([0 120])
title('Time step')
ylabel('time step (ms)')
xlabel('n nerurons')
set(gca, 'xtick', 1:length(data), 'xticklabel', {data(:,2)})
