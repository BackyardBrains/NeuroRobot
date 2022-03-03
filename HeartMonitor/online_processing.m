

%%
spikerbox = arduino('COM8','Uno');

%% Prepare
clc
duration_in_s = 10;
step_time_in_s = 0.05;
spike_threshold = 4;
nsteps = duration_in_s * (1/step_time_in_s);
data = zeros(nsteps, 6);

fs = 1/step_time_in_s;
l_edge = 0.2 * fs;
r_edge = 0.4 * fs;

%% Prepare figure
figure(1)
clf
plot_ecg = plot(data(:,1), 'linestyle', '-', 'linewidth', 2, 'color', [0.2 0.4 0.8]);
hold on
plot_q = plot([20 40 60 80], [0 0 0 0], 'marker', 'o', 'linestyle', 'none', 'markersize', 10, 'color', 'r');
plot_r = plot([20 40 60 80], [0 0 0 0], 'marker', 'o', 'linestyle', 'none', 'markersize', 10, 'color', [0.1 0.8 0.1]);
plot_s = plot([20 40 60 80], [0 0 0 0], 'marker', 'o', 'linestyle', 'none', 'markersize', 10, 'color', 'b');
plot_front = plot([0 0], [0 5], 'color', 'k', 'linestyle', '-', 'linewidth', 2);
xlim([1 nsteps])
ylim([0 6])

%%
nstep = 0;
refractory = 0;
tic
while nstep <= (duration_in_s * (1/step_time_in_s))
    
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

