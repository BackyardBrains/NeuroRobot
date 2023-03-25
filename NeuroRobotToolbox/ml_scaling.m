
x = [20000 282000]; % ntuples

% y = [1000 5000];
y = [100 300];
% y = [2000 10017];
% y = [100 500];
% y = [20 33];

figure(1)
clf
plot(x, y, 'linestyle', 'none', 'marker', '.', 'markersize', 30)
xlabel('ntuples')
ylabel('nsmall')
title('Optimal ML settings depend on dataset size')



