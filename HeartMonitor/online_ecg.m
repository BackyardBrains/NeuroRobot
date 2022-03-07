
% Script for online identification of QRS timepoints in ECG data recorded
% with the BYB Heart and Brain SpikerBox
% By Christopher Harris


%% Connect SpikerBox
clear spikerbox
spikerbox = arduino('COM17','Uno'); % Use Device Manager to find SpikerBox COM port

%% Prepare
duration_in_s = 10;
step_time_in_s = 0.05;
spike_threshold = 4;
fs = 1/step_time_in_s;
l_edge = 0.2 * fs;
r_edge = 0.4 * fs;
nsteps = duration_in_s * (1/step_time_in_s);
data = zeros(nsteps, 6);
flag = 0;

%% Prepare figure
figure(1)
clf
set(1, 'position', [376 700 1045 239], 'color', 'w')
ax = axes('position', [0.1 0.3 0.8 0.6]);
plot_ecg = plot(data(:,1), 'linestyle', '-', 'linewidth', 2, 'color', [0.2 0.4 0.8]);
hold on
plot_q = plot([20 40 60 80], [0 0 0 0], 'marker', 'o', 'linestyle', 'none', 'markersize', 10, 'color', [0.2 0.8 0.2], 'DisplayName','Q', 'linewidth', 2);
plot_r = plot([20 40 60 80], [0 0 0 0], 'marker', 'o', 'linestyle', 'none', 'markersize', 10, 'color', [0.8 0.4 0.2], 'DisplayName','R', 'linewidth', 2);
plot_s = plot([20 40 60 80], [0 0 0 0], 'marker', 'o', 'linestyle', 'none', 'markersize', 10, 'color', [0.2 0.4 0.8], 'DisplayName','S', 'linewidth', 2);
plot_front = plot([0 0], [0 5], 'color', 'k', 'linestyle', '-', 'linewidth', 2);
xlim([1 nsteps])
bstop = uicontrol('Style', 'pushbutton', 'String', 'Stop', 'units', 'normalized', 'position', [0.4 0.05 0.2 0.1]);
set(bstop, 'Callback', 'flag = 1;')

%% Record and process data
nstep = 0;
refractory = 0;
tic
while nstep <= (duration_in_s * (1/step_time_in_s)) && ~flag
    
    nstep = nstep + 1;
    data(nstep, :) = 0;
    
    dat = readVoltage(spikerbox, "A0");
    data(nstep, 1) = dat;    
    while toc < (step_time_in_s * nstep)
        pause(step_time_in_s/100)
    end
    data(nstep, 2) = toc;
    plot_ecg.YData = data(:,1);    

    if dat > spike_threshold && ~refractory && nstep > l_edge
        data(nstep, 3) = 1;
        [~, q_ind] = min(data(nstep - l_edge: nstep, 1));
        data(nstep - l_edge + q_ind - 1, 4) = 1;
        refractory = r_edge;
    end

    if refractory == 1
        refractoy = 0;
        if nstep > (l_edge + r_edge)
            [~, p_ind] = min(data(nstep - r_edge + 1: nstep, 1));
            data(nstep - r_edge + p_ind, 5) = 1;
        end
    end

    if refractory
        refractory = refractory - 1;
    end    

    beats = find(data(:,3));

    if ~isempty(beats)
        these_times = data(beats, 2);
        this_heart_rate = (1/(median(diff(these_times)))) * 60;
        disp(num2str(this_heart_rate))
        data(nstep, 6) = this_heart_rate;
    end
    
    plot_r.XData = beats;
    plot_r.YData = data(beats, 1);

    qs = find(data(:,4));
    plot_q.XData = qs;
    plot_q.YData = data(qs, 1);

    ss = find(data(:,5));
    plot_s.XData = ss;
    plot_s.YData = data(ss, 1);

    plot_front.XData = [nstep nstep];

     if nstep == nsteps
        nstep = 0;
    end
end

