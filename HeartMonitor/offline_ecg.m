
% This script identifies QRS timepoints in ECG data recorded
% with the BYB Heart and Brain SpikerBox
% Written by Christopher Harris, 2022

close all
clear
clc

%% Load data
file_name = 'BYB_Recording_2022-03-07_10.44.50.wav';
[data, fs] = audioread(file_name);
nsteps = length(data(:,1));

%% Get R waves
spike_threshold = prctile(data(:,1), 98);
ismax = find(islocalmax(data(:,1), 'MinProminence', 0.4, 'MinSeparation', 0.2 * fs));
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

%% Get instantaneous heart rate
BPM = diff(ismax/fs) * 60;
BPM = padarray(BPM, 1, nan, 'post');

%% Save results
output_file_name = horzcat(file_name(1:end-4), '.xlsx');
Q = qrs_times(:,2);
R = qrs_times(:,1);
S = qrs_times(:,3);
QSduration = qrs_times(:,4);
T = table(Q, R, S, QSduration, BPM);
writetable(T, output_file_name)

%% Plot results
figure(1)
clf
set(1, 'position', [71 154 1400 700], 'color', 'w')

subplot(2,1,1)
plot(data(:,1), 'linestyle', '-', 'linewidth', 1.5, 'color', [0.2 0.2 0.2], 'DisplayName', 'ECG');
hold on
plot(qrs_times(:,1), data(qrs_times(:,1),1), 'marker', 'o', 'linestyle', 'none', 'markersize', 8, 'color', [0.8 0.4 0.2], 'DisplayName','R wave', 'linewidth', 1.5);
plot(qrs_times(:,2), data(qrs_times(:,2),1), 'marker', 'o', 'linestyle', 'none', 'markersize', 8, 'color', [0.2 0.8 0.2], 'DisplayName','Q wave', 'linewidth', 1.5);
plot(qrs_times(:,3), data(qrs_times(:,3),1), 'marker', 'o', 'linestyle', 'none', 'markersize', 8, 'color', [0.2 0.4 0.8], 'DisplayName','S wave', 'linewidth', 1.5);
xlim([0 nsteps])
ylim([-spike_threshold spike_threshold * 2])
legend('NumColumns', 4)
title('ECG')
xlabel('Time (0.1 ms steps)')
ylabel('Adjusted voltage')

subplot(2,1,2)
plot(BPM)
title('Instantaneous heart rate')
xlabel('Heart beats')
ylabel('BPM')
