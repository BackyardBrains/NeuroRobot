

%% Definition
nneurons = 500;
a = 0.02 * ones(nneurons,1);
b = 0.15 * ones(nneurons,1);
c = -65 + 5 * rand(nneurons,1) .^ 2;
d = 8 - 6 * rand(nneurons,1) .^ 2;
connectome = zeros(nneurons);
v = -65 + 5 * rand(nneurons,1) .^ 2;
u = b .* v;
plast = 0; % Plastic synapses (%)
imx_sens = 10; % Visual input (%)
imx_moto = 0; % Motor output (%)
imx_net = 1;


%% Vehicle
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


%% Organization
imx_rands = randsample(length(brain_im_xy), nneurons); 
neuron_xys = brain_im_xy(imx_rands, :);
for presynaptic_neuron = 1:nneurons
    for postsynaptic_neuron = 1:nneurons
        
        % Euclidian distance between neurons
        this_weight = 0;
        xe = abs(neuron_xys(presynaptic_neuron, 1) - neuron_xys(postsynaptic_neuron, 1));
        ye = abs(neuron_xys(presynaptic_neuron, 2) - neuron_xys(postsynaptic_neuron, 2));
        ce = sqrt(xe^2 + ye^2);
        if ce <= 0.4
            this_weight = 10;
        elseif ce < 0.8
            this_weight = -20;
        end
        connectome(presynaptic_neuron, postsynaptic_neuron) = this_weight;
        
    end
    
    sens_neuron = rand <= imx_sens / 100;
    this_contact = randsample(2,1);
    neuron_contacts(presynaptic_neuron, this_contact) = sens_neuron;
    if sens_neuron
        this_val = 1;
    else
        this_val = 0;
    end
    vis_prefs(presynaptic_neuron, randsample(3,1), this_contact) = this_val;

end

