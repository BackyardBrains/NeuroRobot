

%% Settings
nneurons = 25;


%% Prepare
a = 0.02 * ones(nneurons,1);
b = 0.15 * ones(nneurons,1);
c = -65 + 5 * rand(nneurons,1) .^ 2;
d = 8 - 6 * rand(nneurons,1) .^ 2;
connectome = zeros(nneurons);
v = -65 + 5 * rand(nneurons,1) .^ 2;
u = b .* v;
brain = struct;
neuron_contacts = zeros(nneurons, 13);
vis_prefs = zeros(nneurons, 23, 2);
dist_prefs = zeros(nneurons, 1);
audio_prefs = zeros(nneurons, 1);
network_ids = ones(nneurons, 1);
da_rew_neurons = zeros(nneurons, 1);
neuron_tones = zeros(nneurons, 1);
bg_neurons = zeros(nneurons, 1);
da_connectome = zeros(nneurons, nneurons, 3);
neuron_cols(:, 1:3) = repmat([1 0.9 0.8], [nneurons, 1]);
steps_since_last_spike(1:nneurons) = nan;
network = struct;
nnetworks = length(unique(network_ids));
network_drive = zeros(nnetworks, 3);
spikes_loop = zeros(nneurons, ms_per_step * nsteps_per_loop);
neuron_xys = zeros(nneurons, 2);


%% Anatomy
xrange = linspace(-1.5, 1.5, sqrt(nneurons));
yrange = linspace(1.3, -1.7, sqrt(nneurons));
[xg,yg] = meshgrid(xrange,yrange);
counter = 0;
for nx = 1:sqrt(nneurons)
    for ny = 1:sqrt(nneurons)
        counter = counter + 1;
        neuron_xys(counter, :) = [xg(nx, ny), yg(nx, ny)];
    end
end
for nneuron = 1:nneurons - 1
    this_weight = 25;
    connectome(nneuron, nneuron + 1) = this_weight;
    da_connectome(nneuron, nneuron + 1, 1) = 1;
    da_connectome(nneuron, nneuron + 1, 2) = this_weight;   
    da_connectome(nneuron, nneuron + 1, 3) = 0;      
end

