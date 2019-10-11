

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

neuron_xys = zeros(nneurons, 2);
n = nneurons;
eqdist_const = 0.01; % 0.006;         
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
    xys(2) = xys(2) - 0;
    neuron_xys(nneuron, :) = xys;
end


% Save brain
brain.nneurons = nneurons;
brain.neuron_xys = neuron_xys;
brain.connectome = connectome;
brain.da_connectome = da_connectome;
brain.a_init = 0.2;
brain.b_init = 0.02;
brain.c_init = -65;
brain.d_init = 2;
brain.w_init = 0;
brain.a = a;
brain.b = b;
brain.c = c;
brain.d = d;
brain.v = v;
brain.u = u;
brain.neuron_contacts = neuron_contacts;
brain.vis_prefs = vis_prefs;
brain.audio_prefs = audio_prefs;
brain.dist_prefs = dist_prefs;
brain.neuron_cols = neuron_cols;
brain.network_ids = network_ids;
brain.da_rew_neurons = da_rew_neurons;
brain.neuron_tones = neuron_tones;
brain.network_drive = network_drive;
brain.network = network;
brain.bg_neurons = bg_neurons;
brain_file_name = strcat('C:/Users/Christopher Harris/NeuroRobot/Matlab/Brains/', brain_name, '.mat');
save(brain_file_name, 'brain')
disp('Brain saved')


