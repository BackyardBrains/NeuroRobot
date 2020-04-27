
%% Core

Ne = 400;
Ni = 100;

re = rand(Ne,1);
ri = rand(Ni,1);

a = [0.02 * ones(Ne,1); 0.02 + 0.08 * ri];
b = [0.2 * ones(Ne,1); 0.25 - 0.05 * ri];
c = [-65 + 15 * re .^ 2; -65 * ones(Ni,1)];
d = [8 - 6 * re .^ 2; 2 * ones(Ni,1)];

connectome = [0.5 * rand(Ne + Ni, Ne), -rand(Ne + Ni, Ni)];

v = [-65 + 15 * re .^ 2; -65 * ones(Ni,1) .* ri .^ 2];
u = b .* v;

nneurons = Ne + Ni; % Number of Neurons
bflip = randsample(nneurons, nneurons);

a = a(bflip);
b = b(bflip);
c = c(bflip);
d = d(bflip);
v = v(bflip);
u = u(bflip);

connectome2 = zeros(nneurons, nneurons);
for nneuron = 1:nneurons
    connectome2(:, nneuron) = connectome(:, bflip(nneuron));
end
connectome = connectome2;



%% Suit
plast = 0; % Plastic synapses (%)
imx_sens = 10; % Visual input (%)
imx_moto = 0; % Motor output (%)
imx_net = 1;

% space evenly
imx_rands = randsample(length(brain_im_xy), nneurons); 
neuron_xys = brain_im_xy(imx_rands, :);


clear vis_prefs
clear dist_prefs
clear audio_prefs
clear bg_neurons
clear neuron_contacts


% connectome architecture
da_connectome = zeros(nneurons, nneurons, 3);

for presynaptic_neuron = 1:nneurons
    for postsynaptic_neuron = 1:nneurons
        
        %%% Architectue 2
        if 0
            xe = abs(neuron_xys(presynaptic_neuron, 1) - neuron_xys(postsynaptic_neuron, 1));
            ye = abs(neuron_xys(presynaptic_neuron, 2) - neuron_xys(postsynaptic_neuron, 2));
            ce = sqrt(xe^2 + ye^2);
            if ce <= 0.6

            elseif ce < 1.2

            end
            connectome(presynaptic_neuron, postsynaptic_neuron) = this_weight;
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 1) = 0;
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 2) = 0;   
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 3) = 0;  
        else
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 1) = 0;
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 2) = 0;   
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
    neuron_contacts(presynaptic_neuron, moto(m_val).contacts) = moto_neuron * 1;              
end

% Other variables
spikes_loop = zeros(nneurons, ms_per_step * nsteps_per_loop);
neuron_cols(1 : nneurons, 1:3) = repmat([1 0.9 0.8], [nneurons, 1]);  
network_ids(1 : nneurons, 1) = imx_net;
da_rew_neurons(1 : nneurons, 1) = 0;
steps_since_last_spike(1 : nneurons) = nan;
neuron_tones(1 : nneurons, 1) = 0;
if ext_cam_id
    save_firing = zeros(nneurons, ext_cam_nsteps, 'logical');
end
nnetworks = length(unique(network_ids));
network_drive = zeros(nnetworks, 3);
