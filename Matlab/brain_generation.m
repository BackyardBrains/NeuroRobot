

%% Load brain parameters and connectome
load bursting_brain
nneurons = size(a, 1);


%% Build brain vehicle
brain = struct;
clear v
v(:, 1) = -65 + 5 * randn(nneurons,1);
u = b .* v;
neuron_contacts = zeros(nneurons, 13);
vis_prefs = zeros(nneurons, 23, 2);
dist_prefs = zeros(nneurons, 1);
audio_prefs = zeros(nneurons, 1);
network_ids = ones(nneurons, 1);
da_rew_neurons = zeros(nneurons, 1);
neuron_tones = zeros(nneurons, 1);
bg_neurons = zeros(nneurons, 1);
da_connectome = zeros(nneurons, nneurons, 3);
clear neuron_cols
neuron_cols(:, 1:3) = repmat([1 0.9 0.8], [nneurons, 1]);
clear steps_since_last_spike
steps_since_last_spike(1:nneurons) = nan;
for nneuron = nneurons
    for nneuron2 = 1:nneurons
        da_connectome(nneuron, nneuron2, 2) = connectome(nneuron, nneuron2);
    end
end  
spikes_loop = []; % This is not what's in load_or_initialize_brain.m
network = struct;
nnetworks = length(unique(network_ids));
network_drive = zeros(nnetworks, 3);


%% Get XYs
neuron_xys = zeros(nneurons, 2);
n = nneurons;
eqdist_const = 0.006;          
xx = eqdist_const * n + 0.6;
npoints = round(2*sqrt(n));
phi = (sqrt(5)+1)/2;
for nneuron = 1:n
    if nneuron > n - npoints
        r = 1;
    else
        r = sqrt(nneuron-1/2)/sqrt(n-(npoints+1)/2);
    end    
    theta = 2*pi*nneuron/phi^2;
    xys = [r*cos(theta), r*sin(theta)];
    xys = xys * xx;
    xys(2) = xys(2) - 0.35;
    neuron_xys(nneuron, :) = xys;
end

