
% Script for offline identification of QRS timepoints in ECG data recorded
% with the BYB Heart and Brain SpikerBox
% By Christopher Harris


%% Load data
[data, fs] = audioread('BYB_Recording_2022-03-07_10.44.50.wav');
nsteps = length(data(:,1));

%% Get R waves
spike_threshold = prctile(data(:,1), 98);
ismax = find(islocalmax(data(:,1), 'MinProminence', 0.4));
ismax(data(ismax, 1) < spike_threshold) = [];
l_edge = 0.2 * fs;
r_edge = 0.2 * fs;
ismax(ismax < l_edge | ismax > nsteps-r_edge) = [];
nwaves = length(ismax);

%% Get Q and S waves
qrs_times = zeros(nwaves, 4);
qrs_times(:,1) = ismax;
for ii = 1:nwaves
    pre_win = data(ismax(ii)-l_edge : ismax(ii), 1);
    [q_val, q_ind] = min(pre_win);
    qrs_times(ii, 2) = (ismax(ii)-l_edge) + q_ind - 1;
    post_win = data(ismax(ii) : ismax(ii)+r_edge, 1);
    [s_val, s_ind] = min(post_win);
    qrs_times(ii, 3) = ismax(ii) + s_ind - 1;
    qrs = qrs_times(ii,3) - qrs_times(ii,2);
    qrs_times(ii,4) = qrs;
end

%% Plot
figure(1)
clf
set(1, 'position', [376 50 1045 179], 'color', 'w')
plot(data(:,1), 'linestyle', '-', 'linewidth', 2, 'color', [0.2 0.2 0.2], 'DisplayName', 'ECG');
hold on
plot(qrs_times(:,1), data(qrs_times(:,1),1), 'marker', 'o', 'linestyle', 'none', 'markersize', 10, 'color', [0.8 0.4 0.2], 'DisplayName','R', 'linewidth', 2);
plot(qrs_times(:,2), data(qrs_times(:,2),1), 'marker', 'o', 'linestyle', 'none', 'markersize', 10, 'color', [0.2 0.8 0.2], 'DisplayName','Q', 'linewidth', 2);
plot(qrs_times(:,3), data(qrs_times(:,3),1), 'marker', 'o', 'linestyle', 'none', 'markersize', 10, 'color', [0.2 0.4 0.8], 'DisplayName','S', 'linewidth', 2);
xlim([0 nsteps])

