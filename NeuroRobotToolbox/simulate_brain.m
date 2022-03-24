
clear

%% Settings
load_name = 'Critter 3';
duration_in_sec = 100;
input_neurons = 1;
input_value = 50;
output_neurons = 13:16;
disabled_neurons = [];

%% Prepare
ms_per_step = 100;
bg_colors = 1;
brain_selection_val = 2;
nsteps_per_loop = 1;
dist_I = 0;
audio_I = 0;
load_or_initialize_brain
ts = ms_per_step * duration_in_sec;
spike_log = zeros(nneurons, ts);

%% Modify connectome
connectome(connectome == -20) = -40;

%% Run
for nstep = 1:duration_in_sec
    vis_I = zeros(nneurons, 1);
    if nstep > duration_in_sec / 2
        vis_I(input_neurons) = input_value;
    end
    for t = 1:ms_per_step
        I = 5 * randn(nneurons, 1);       
        fired_now = v >= 30;
        fired_now(disabled_neurons) = 0;
        spike_log(fired_now, t + ((nstep - 1) * ms_per_step)) = 1;
        v(fired_now) = c(fired_now);
        u(fired_now) = u(fired_now) + d(fired_now);
        I = I + sum(connectome(fired_now,:), 1)';
        I = I + vis_I + dist_I + audio_I;
        v = v + 0.5 * (0.04 * v.^2 + 5 * v + 140 - u + I);
        v = v + 0.5 * (0.04 * v.^2 + 5 * v + 140 - u + I);
        u = u + a .* (b .* v - u);
        v(isnan(v)) = c(isnan(v));
    end
end

%% Plot
figure(10)
clf
imagesc(spike_log(:, :))
hold on
plot([ts/2 ts/2], [0.5 nneurons + 0.5], 'color', 'r', 'linewidth', 2)
rectangle('pos', [1 output_neurons(1) - 0.5 ts output_neurons(end) - output_neurons(1) + 1], 'edgecolor', 'g', 'linewidth', 2)
set(gca, 'ytick', 1:nneurons)
xlabel('ms')
