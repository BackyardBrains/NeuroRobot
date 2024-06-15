

%% Settings
nneurons = 100;


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
neuron_scripts = zeros(nneurons, 1);


%% Anatomy
counter = 0;
while counter < nneurons
    imx_rand = randsample(length(brain_im_xy), 1);
    neuron_xy = brain_im_xy(imx_rand, :);
    ce = sqrt(neuron_xy(1)^2 + neuron_xy(2)^2);
    if ce > 1 && ce < 1.25
        counter = counter + 1;
        neuron_xys(counter, :) = neuron_xy;
    end
end

for presynaptic_neuron = 1:nneurons
    
    % Connectome
    for postsynaptic_neuron = 1:nneurons
        
            % Euclidian distance between neurons
            this_weight = 0;
            xe = abs(neuron_xys(presynaptic_neuron, 1) - neuron_xys(postsynaptic_neuron, 1));
            ye = abs(neuron_xys(presynaptic_neuron, 2) - neuron_xys(postsynaptic_neuron, 2));
            ce = sqrt(xe^2 + ye^2);
                   
            if ce <= 0.2 && rand < 0.5
                this_weight = 20 * rand;
            end
            
            connectome(presynaptic_neuron, postsynaptic_neuron) = this_weight;
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 1) = 2;
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 2) = this_weight;   
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 3) = 0;      
            
    end
    
    % Motor output
    if rand < 0.2
        m_val = randsample(4,1);
        moto(1).contacts = [6, 8];
        moto(2).contacts = [7, 9];
        moto(3).contacts = [10, 12];
        moto(4).contacts = [11, 13];
        neuron_contacts(presynaptic_neuron, moto(m_val).contacts) = 100 * rand;
    end
end

clear presynaptic_neuron
clear postsynaptic_neuron

draw_brain
