

% This script is inserted into location_in_brain_selected to override network generation during NMA
% User builds neuronal and synaptic properties algorithmically 


n = 1000; % Neurons (1000)
imx_con = 25; % Connectivity (25 %)
weight = 12; % Synapse weights (2)
plast = 0; % Plastic synapses (0 %)
imx_sens = 0; % Visual input (0 %)
imx_moto = 0; % Motor output (0 %)
imx_net = 1;

this_a = 0.02;
this_b = 0.15;
this_c = -65;
this_d = 2;

% space evenly
imx_rands = randsample(length(brain_im_xy), n); 
neuron_xys = brain_im_xy(imx_rands, :);

% connectome architecture
for presynaptic_neuron = nneurons + 1:nneurons + n
    for postsynaptic_neuron = nneurons + 1:nneurons + n
        
        if abs(neuron_xys(presynaptic_neuron, 1) - neuron_xys(postsynaptic_neuron, 1)) < 0.2 && ...
            abs(neuron_xys(presynaptic_neuron, 2) - neuron_xys(postsynaptic_neuron, 2)) < 0.2
            connected = rand <= 0.6;
            connected = connected * sign(rand-0.1);
            connectome(presynaptic_neuron, postsynaptic_neuron) = connected * weight;
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 1) = rand <= 0.1;
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 2) = connected * weight;   
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 3) = 0;  
        end
    end            

    % Sensory input
    sens_neuron = rand <= imx_sens / 100;
    this_contact = randsample(2,1);
    neuron_contacts(presynaptic_neuron, this_contact) = sens_neuron;
    if sens_neuron
        this_val = 1;
    else
        this_val = 0;
    end
    vis_prefs(presynaptic_neuron, randsample(3,1), this_contact) = this_val;
    dist_prefs(presynaptic_neuron, 1) = 0;
    audio_prefs(presynaptic_neuron, 1) = 0;
    bg_neurons(presynaptic_neuron, 1) = 0;

    % Motor output
    moto_neuron = rand <= imx_moto / 100;
    m_val = randsample(4,1);
    moto(1).contacts = [6, 8];
    moto(2).contacts = [7, 9];
    moto(3).contacts = [10, 12];
    moto(4).contacts = [11, 13];
    neuron_contacts(presynaptic_neuron, moto(m_val).contacts) = moto_neuron * 250;              
end

% Other variables
spikes_loop = zeros(nneurons + n, ms_per_step * nsteps_per_loop);
a(nneurons + 1 : nneurons + n, 1) = this_a;
b(nneurons + 1 : nneurons + n, 1) = this_b;
c(nneurons + 1 : nneurons + n, 1) = this_c;
d(nneurons + 1 : nneurons + n, 1) = this_d;
v(nneurons + 1 : nneurons + n, 1) = this_c + 5 * randn(n,1);
u = b .* v;
neuron_cols(nneurons + 1 : nneurons + n, 1:3) = repmat(col, [n, 1]);  
network_ids(nneurons + 1 : nneurons + n, 1) = imx_net;
da_rew_neurons(nneurons + 1 : nneurons + n, 1) = 0;
steps_since_last_spike(nneurons + 1 : nneurons + n) = nan;
neuron_tones(nneurons + 1 : nneurons + n, 1) = 0;
nneurons = nneurons + n;
if ext_cam_id
    save_firing = zeros(nneurons, ext_cam_nsteps, 'logical');
end
nnetworks = length(unique(network_ids));
network_drive = zeros(nnetworks, 3);
