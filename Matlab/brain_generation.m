

% BRAIN GENERATION for NEUROROBOT APP by Backyard Brains
% By Christopher Harris, Neurorobotics Lead at Backyard Brains (christopher@backyardbrains.com)
%
% This script generates a brain at a random point in brain search space.
%
% Aims:
% Explore brain search space
% Deliniate space containing working brains
% Apply Matlab ML and generative ANNs to existing brains and new brains that receive significant reward from interns
% Collect data for generative reinforcement learning
% Generate better brains
%
% This code is licensed under a GNU 2.1 license

nneurons = 100;

p_connect = 0.1;
synmin = -5;
synmax = 5;
motormax = 70;

nnetworks = 6;
network_output_dropout = [1 3 5];

a = zeros(nneurons, 1);
b = zeros(nneurons, 1);
c = zeros(nneurons, 1);
d = zeros(nneurons, 1);
neuron_contacts = zeros(nneurons, 13);
vis_prefs = zeros(nneurons, 23, 2);
dist_prefs = zeros(nneurons, 1);
network_ids = zeros(nneurons, 1);
da_rew_neurons = zeros(nneurons, 1);
neuron_tones = zeros(nneurons, 1);
bg_neurons = zeros(nneurons, 1);
connectome = zeros(nneurons, nneurons);
da_connectome = zeros(nneurons, nneurons, 3);

clear neuron_cols
clear steps_since_last_spike

if use_cnn
    nviscategories = 23;
else
    nviscategories = 6;
end

for nneuron = 1:nneurons
    
    %% Izhikevich dimensions
%     a(nneuron, 1) = randsample(0:0.0001:0.15, 1); original
    a(nneuron, 1) = 0.2;
%     b(nneuron, 1) = randsample(0:0.0001:0.5, 1); % original
    b(nneuron, 1) = randsample(0.1:0.0001:0.25, 1);
%     c(nneuron, 1) = randsample(-100:0.0001:0, 1); % original
    c(nneuron, 1) = randsample(-70:0.0001:-50, 1);
%     d(nneuron, 1) = randsample(0:0.0001:10, 1); % original
    d(nneuron, 1) = 2;
    
    %% Left cam
    neuron_contacts(nneuron, 1) = randsample([0 1], 1);
    if neuron_contacts(nneuron, 1)
        vis_prefs(nneuron, randsample(1:nviscategories, 1), 1) = randsample([0 1], 1);
    end
    
    %% Right cam
    neuron_contacts(nneuron, 2) = randsample([0 1], 1);
    if neuron_contacts(nneuron, 2)
        vis_prefs(nneuron, randsample(1:nviscategories, 1), 2) = randsample([0 1], 1);
    end
    
    %% Microphone
%     neuron_contacts(nneuron, 3) = randsample(0:1, 1); original
    neuron_contacts(nneuron, 3) = 0; %  microphone not in use yet
    
    %% Speaker
    neuron_contacts(nneuron, 4) = randsample([0 100], 1);
    if neuron_contacts(nneuron, 4) == 100 % This is just to set the axon width
        neuron_tones(nneuron) = randsample(50:700, 1);
    end
    
    %% Distance sensor
    neuron_contacts(nneuron, 5) = randsample([0 1], 1);
    if neuron_contacts(nneuron, 5)
        dist_prefs(nneuron) = randsample(1:3, 1);
    end
    
    %% Motors
    neuron_contacts(nneuron, 6:13) = randsample(0:motormax, 8);
    
    %% Connectome
    for nneuron2 = 1:nneurons
        if rand < p_connect
            connectome(nneuron, nneuron2) = randsample(synmin:synmax, 1);
            da_connectome(nneuron, nneuron2, 1) = randsample(0:2, 1);
            da_connectome(nneuron, nneuron2, 2) = connectome(nneuron, nneuron2);
            da_connectome(nneuron, nneuron2, 3) = 0;
        end
    end    
    
    %% Dopamine neurons
    da_rew_neurons(nneuron) = 0;
    if da_rew_neurons(nneuron)
        neuron_contacts(nneuron, :) = 0;
        connectome(nneuron, :) = 0;
        da_connectome(nneuron, :, :) = 0;
    end
    
    %% Basal ganglia neurons and networks
    if nnetworks > 1 && ~da_rew_neurons(nneuron)
        bg_neurons(nneuron) = randsample([0 0 0 0 1], 1);
        network_ids(nneuron) = randsample(1:nnetworks, 1);
        if bg_neurons(nneuron) && network_ids(nneuron) == 1
            network_ids(nneuron) = randsample(2:nnetworks, 1);
            b(nneuron) = 0.1;
            c(nneuron) = -65;
        end
    end
    
    %% Reduce motor output
    if sum(network_ids(nneuron) == network_output_dropout)
        neuron_contacts(nneuron, [4, 6:13]) = 0;
    end

end

%% Reduce input on BG neurons
for nneuron = 1:nneurons
    if bg_neurons(nneuron)
        connectome(:, nneuron) = connectome(:, nneuron) * 0.1;
        da_connectome(:, nneuron, 2) = da_connectome(:, nneuron, 2) * 0.1;
    end
end

%% Build brain vehicle
brain = struct;
c_init = -65;
clear v
v(:, 1) = c_init + 5 * randn(nneurons,1);
u = b .* v;
col = [1 0.9 0.8];
neuron_cols(:, 1:3) = repmat(col, [nneurons, 1]);  
steps_since_last_spike(1:nneurons) = nan;
spikes_loop = [];
network = struct;
nnetworks = length(unique(network_ids));
network_drive = zeros(nnetworks, 3);

%% Get XYs
neuron_xys = zeros(nneurons, 2);
n = nneurons;
eqdist_const = 0.01;          
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
    xys(2) = xys(2) - 0.2;
    neuron_xys(nneuron, :) = xys;
end  
