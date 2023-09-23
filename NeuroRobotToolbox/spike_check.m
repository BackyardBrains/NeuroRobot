
%%
% rec_dir_name = 'Rec5';
rec_dir_name = '';

dataset_dir_name = 'C:\SpikerBot ML Datasets\';

spike_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*spikes_step.mat'));
nsteps = size(spike_dir, 1);
load(horzcat(spike_dir(1).folder, '\', spike_dir(1).name))
nneurons = size(spikes_step, 1);
ms_per_step = size(spikes_step, 2);
spikes_step = zeros(nneurons, ms_per_step);
data = zeros(nsteps, 1);

these_neurons = find(neuron_tones);
% these_neurons = 14:18;

%%
for nstep = 1:nsteps
    if ~rem(nstep, round(nsteps/10))
        disp(horzcat(num2str(round((100*nstep)/nsteps)), '%'))
    end
    load(horzcat(spike_dir(nstep).folder, '\', spike_dir(nstep).name))
    data(nstep) = sum(sum(spikes_step(these_neurons, :)));
end

%%
data2 = smoothdata(data);
[vals, inds] = findpeaks(data2, 'MinPeakDistance', 50, 'MinPeakProminence', 2);
this_mean = round(mean(diff(inds)/10));
this_std = round(std(diff(inds)/10));
horzcat('Avg. inter-peak interval = ', num2str(this_mean), ' ± ', num2str(this_std), ' s')

figure(1)
clf
plot(data2)
hold on
plot(inds, vals, 'marker', 'v', 'linestyle', 'none')
title(horzcat('Spikes per step (peak interval = ', num2str(this_mean), ' ± ', num2str(this_std), ' s)'))


