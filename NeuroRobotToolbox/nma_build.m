

% This script is inserted into location_in_brain_selected to override network generation during NMA
% User builds neuronal and synaptic properties algorithmically 


n = 700; % Neurons (1000)
imx_con = 20; % Connectivity (25 %)
weight = 15; % Synapse weights (2)
plast = 0; % Plastic synapses (0 %)
imx_sens = 2; % Visual input (0 %)
imx_moto = 0; % Motor output (0 %)
imx_net = 1;

this_a = 0.02;
this_b = 0.15;
this_c = -65;
this_d = 8;

% space evenly
imx_rands = randsample(length(brain_im_xy), n); 
neuron_xys = brain_im_xy(imx_rands, :);

% connectome architecture
for presynaptic_neuron = nneurons + 1:nneurons + n
    for postsynaptic_neuron = nneurons + 1:nneurons + n
        
        %%% Architecture 1
%         if abs(neuron_xys(presynaptic_neuron, 1) - neuron_xys(postsynaptic_neuron, 1)) < 0.3 && ...
%             abs(neuron_xys(presynaptic_neuron, 2) - neuron_xys(postsynaptic_neuron, 2)) < 0.3
%             if rand <= (imx_con / 100)
%                 this_weight = weight + weight * 0.1 * randn;
%                 connectome(presynaptic_neuron, postsynaptic_neuron) = this_weight * sign(rand-0.2);
%                 da_connectome(presynaptic_neuron, postsynaptic_neuron, 1) = rand <= 0.1;
%                 da_connectome(presynaptic_neuron, postsynaptic_neuron, 2) = this_weight * sign(rand-0.2);   
%                 da_connectome(presynaptic_neuron, postsynaptic_neuron, 3) = 0;  
%             end
%         end

        %%% Architectue 2
        if rand <= (imx_con / 100)
            xe = abs(neuron_xys(presynaptic_neuron, 1) - neuron_xys(postsynaptic_neuron, 1));
            ye = abs(neuron_xys(presynaptic_neuron, 2) - neuron_xys(postsynaptic_neuron, 2));
            ce = sqrt(xe^2 + ye^2);

            if ce <= 0.6
                this_weight = 30 - ce * 100;
                this_weight = this_weight + this_weight * sign(this_weight) * 0.2 * randn;
            elseif ce < 1.2
                this_weight = -30 - 30 * 0.2 * randn;
            end
            connectome(presynaptic_neuron, postsynaptic_neuron) = this_weight;
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 1) = rand <= 0.1;
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 2) = this_weight;   
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
a(nneurons + 1 : nneurons + n, 1) = this_a + this_a * 2 * 0.1 * randn(n,1);
b(nneurons + 1 : nneurons + n, 1) = this_b + this_b * 2 * 0.01 * randn(n,1);
c(nneurons + 1 : nneurons + n, 1) = this_c + this_c * 2 * 0.01 * randn(n,1);
d(nneurons + 1 : nneurons + n, 1) = this_d + this_d * 2 * 0.1 * randn(n,1);
v(nneurons + 1 : nneurons + n, 1) = this_c + this_c * 2 * 0.01 * randn(n,1);
u = b .* v;
neuron_cols(nneurons + 1 : nneurons + n, 1:3) = repmat([1 0.9 0.8], [n, 1]);  
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
