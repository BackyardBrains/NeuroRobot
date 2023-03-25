
x = [20000 282000]; % ntuples

% y = [1000 5000]; % nsmall = = 0.01527 * ntuples + 694.7
% y = [2000 10000]; % nmedium = 0.03053 * ntuples + 1389
% y = [100 500]; % treeproperties = 0.001527 * ntuples + 69.47
y = [100 500]; % init_n_unique_states = 0.001527 * ntuples + 69.47
% y = [20 33]; % min_size = 0.00005 * ntuples + 19; 

figure(1)
clf
plot(x, y, 'linestyle', 'none', 'marker', '.', 'markersize', 30)
xlabel('ntuples')
ylabel('nsmall')
title('Optimal ML settings depend on dataset size')



