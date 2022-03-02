

%%
% spikerbox = arduino('COM8','Uno');

%% Prepare
clc
duration_in_s = 15;
step_time_in_s = 0.05;
spikes_to_average = 10;
nsteps = duration_in_s * (1/step_time_in_s);
data = zeros(nsteps, 3);

fs = 1/step_time_in_s;
l_edge = 0.2 * fs;
r_edge = 0.4 * fs;
this_wave = zeros(l_edge + r_edge - 1, spikes_to_average);

%% Prepare figure
figure(1)
clf
plot_ecg = plot(data(:,1), 'linestyle', '-', 'linewidth', 2, 'color', [0.2 0.4 0.8]);
hold on
plot_peaks = plot([20 40 60 80], [0 0 0 0], 'marker', '.', 'linestyle', 'none', 'markersize', 10, 'color', 'r');
plot_front = plot([0 0], [0 5], 'color', 'k', 'linestyle', '-', 'linewidth', 2);
xlim([1 nsteps])
ylim([0 6])

%%
nstep = 0;
spike_time = 0;
nspike = 0;
block = 0;
tic
while nstep <= (duration_in_s * (1/step_time_in_s))
    
    nstep = nstep + 1;
    
    dat = readVoltage(spikerbox, "A0");
    data(nstep, 1) = dat;
    while toc < (step_time_in_s * nstep)
        pause(step_time_in_s/100)
    end
    data(nstep, 2) = toc;
    
    ismax = find(islocalmax(data(:,1), 'MinProminence', 0.75)); % could do simple 4 threshold instead
    ismax(data(ismax, 1) < 4) = [];
    these_times = data(ismax, 2);
    these_times(these_times < 0) = [];

    this_heart_rate = (1/(median(diff(these_times)))) * 60;
    disp(num2str(this_heart_rate))
    data(nstep, 3) = this_heart_rate;

    plot_peaks.XData = ismax;
    plot_peaks.YData = data(ismax, 1);
    plot_ecg.YData = data(:,1);
    plot_front.XData = [nstep nstep];

     if nstep == nsteps
        nstep = 0;
    end
end

