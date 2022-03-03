
%% Get data
% fs = 1/step_time_in_s;
[data, fs] = audioread('SpikeRecorder_data.wav');
nsteps = length(data(:,1));
spike_threshold = prctile(data(:,1), 95);

%% Find R waves
ismax = find(islocalmax(data(:,1), 'MinProminence', 0.5));
ismax(data(ismax, 1) < spike_threshold) = [];
% isnotmax = find(isoutlier(data(ismax, 1)));
% ismax(isnotmax) = [];
l_edge = 0.2 * fs;
r_edge = 0.4 * fs;
ismax(ismax < l_edge | ismax > nsteps-r_edge) = [];
nwaves = length(ismax);

%% Prep
xdata = zeros(nwaves, 4);
xdata(:,1) = ismax;
this_wave = zeros(l_edge + r_edge, 1);
figure(1)
clf

%% Find Q and S waves
for ii = 1:nwaves
    pre_win = data(ismax(ii)-l_edge : ismax(ii), 1);
    [q_val, q_ind] = min(pre_win);
    xdata(ii, 2) = (ismax(ii)-l_edge) + q_ind - 1;
    post_win = data(ismax(ii) : ismax(ii)+r_edge, 1);
    [s_val, s_ind] = min(post_win);
    xdata(ii, 3) = ismax(ii) + s_ind - 1;
    qrs = xdata(ii,3) - xdata(ii,2);
    xdata(ii,4) = qrs;
end

%% Plot
plot_ecg = plot(data(:,1), 'linestyle', '-', 'linewidth', 2, 'color', [0.2 0.2 0.2]);
hold on
plot_r = plot(xdata(:,1), data(xdata(:,1),1), 'marker', 'o', 'linestyle', 'none', 'markersize', 8, 'color', [0.8 0.4 0.2], 'DisplayName','R', 'linewidth', 2);
plot_q = plot(xdata(:,2), data(xdata(:,2),1), 'marker', 'o', 'linestyle', 'none', 'markersize', 8, 'color', [0.2 0.8 0.2], 'DisplayName','Q', 'linewidth', 2);
plot_s = plot(xdata(:,3), data(xdata(:,3),1), 'marker', 'o', 'linestyle', 'none', 'markersize', 8, 'color', [0.2 0.4 0.8], 'DisplayName','S', 'linewidth', 2);
xlim([0 nsteps])
