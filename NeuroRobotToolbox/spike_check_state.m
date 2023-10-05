

nets_dir_name = strcat(userpath, '\Nets\');
net_name = 'patternrecognizer';
load(strcat(nets_dir_name, net_name, '-states'))
nsteps = size(states, 1);

these_states = [8 18];
data = states == these_states;
data = data(:,1) | data(:,2);
data = double(data);
data = data(1:6000);

data2 = smoothdata(data);
[vals, inds] = findpeaks(data2, 'MinPeakDistance', 50, 'MinPeakProminence', 0.9);
this_mean = round(mean(diff(inds)/10));
this_std = round(std(diff(inds)/10));
horzcat('Avg. inter-peak interval = ', num2str(this_mean), ' ± ', num2str(this_std), ' s')

figure(1)
clf
plot(data2)
hold on
plot(inds, vals, 'marker', 'v', 'linestyle', 'none')
title(horzcat('Spikes per step (peak interval = ', num2str(this_mean), ' ± ', num2str(this_std), ' s)'))


