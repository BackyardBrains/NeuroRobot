%% Load or initialize brain
if brain_selection_val > 1
    load(strcat('.\Brains\', load_name, '.mat'))
    nneurons = brain.nneurons;
    neuron_xys = brain.neuron_xys;
    connectome = brain.connectome;
    da_connectome = brain.da_connectome;
    if size(da_connectome, 3) == 2
        da_connectome(:,:,3) = zeros(size(connectome));
    end
    a_init = brain.a_init;
    b_init = brain.b_init;
    c_init = brain.c_init;
    d_init = brain.d_init;
    w_init = brain.w_init;
    a = brain.a;
    b = brain.b;
    c = brain.c;
    d = brain.d;
    v = c + 5 * randn(nneurons, 1);
    u = b .* v;
    spikes_loop = zeros(nneurons, ms_per_step * nsteps_per_loop);
    if isfield(brain, 'spikes_loop')
        brain = rmfield(brain, 'spikes_loop');
    end
    neuron_contacts = brain.neuron_contacts;
    vis_prefs = brain.vis_prefs;
    dist_prefs = brain.dist_prefs;
    neuron_cols = brain.neuron_cols;
    network_ids = brain.network_ids;
    da_rew_neurons = brain.da_rew_neurons;
    try
        neuron_tones = brain.neuron_tones;
    catch
        neuron_tones = zeros(nneurons, 1);
    end
    nnetworks = length(unique(network_ids));
    try
        network = brain.network;
    catch
        for nnetwork = 1:nnetworks
            network(nnetwork).null = []; % Does this even have to be initialized?
        end
    end
    try
        network_drive = brain.network_drive;
        if isempty(network_drive) || size(network_drive, 1) < nnetworks || size(network_drive, 2) == 2
            network_drive = zeros(nnetworks, 3); 
        end
    catch
        network_drive = zeros(nnetworks, 3); 
    end
    try
        bg_neurons = brain.bg_neurons;
    catch
        bg_neurons = zeros(nneurons, 1);
    end
    
elseif brain_selection_val == 1 || ~exist('nneurons', 'var')
  
    brain = struct;
    nneurons = 0;
    neuron_xys = [];
    connectome = [];
    da_connectome = [];
    a_init = 0.02;
    b_init = 0.1;
    c_init = -65;
    d_init = 2;
    w_init = 10;
    a = [];
    b = [];
    c = [];
    d = [];
    v = [];
    u = [];
    spikes_loop = [];
    neuron_contacts = zeros(nneurons, ncontacts);
    vis_prefs = false([1, n_vis_prefs, 2]);
    dist_prefs = zeros(1, 1);
    neuron_cols = [];
    network_ids = 0;
    da_rew_neurons = [];
    neuron_tones = [];
    network = struct; % this will need its subdivisions in design mode
    network_drive = zeros(1, 3);
    nnetworks = 0;
    bg_neurons = [];

    if brain_gen
        brain_generation
    end
end