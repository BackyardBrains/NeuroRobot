
%%
dataset_dir_name = 'C:\SpikerBot ML Datasets\';
rec_dir_name = 'Rec3';
spike_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*spikes_step.mat'));
nsteps = size(spike_dir, 1);
load(horzcat(spike_dir(1).folder, '\', spike_dir(1).name))
nneurons = size(spikes_step, 1);
ms_per_step = size(spikes_step, 2);
spikes_step = zeros(nneurons, ms_per_step);
data = zeros(nsteps, 1);
these_neurons = 14:18;

%%
for nstep = 1:nsteps
    load(horzcat(spike_dir(nstep).folder, '\', spike_dir(nstep).name))
    data(nstep) = sum(sum(spikes_step(these_neurons, :)));
end
figure(1)
clf
plot(data)
title('Spikes per step')
