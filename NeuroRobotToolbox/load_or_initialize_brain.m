%% Load or initialize brain
if brain_selection_val > 1
    if ispc
        load(strcat('.\Brains\', load_name, '.mat'))
    elseif ismac && ~isdeployed
        load(strcat('./Brains/', load_name, '.mat'))
    elseif ismac && isdeployed
        load(strcat(load_name, '.mat'))        
    end
    nneurons = brain.nneurons;
    neuron_xys = brain.neuron_xys;
    connectome = brain.connectome;
    da_connectome = brain.da_connectome;
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
    neuron_contacts = brain.neuron_contacts;
    vis_prefs = brain.vis_prefs;
    dist_prefs = brain.dist_prefs;
    audio_prefs = brain.audio_prefs;
    network_ids = brain.network_ids;
    
    if bg_colors
        network_colors = linspecer(length(unique(network_ids)));
        network_colors(1, :) = [1 0.9 0.8];
    end
    
    da_rew_neurons = brain.da_rew_neurons;
    neuron_tones = brain.neuron_tones;
    neuron_scripts = brain.neuron_scripts;
    nnetworks = length(unique(network_ids)); % There used to be a +1 hack here, removing, testing..
    if isfield(brain, 'network')
        brain = rmfield(brain, 'network');
    end
    
    network_drive = zeros(nnetworks, 3); 
    bg_neurons = brain.bg_neurons;
    
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
    vis_prefs = zeros([1, n_vis_prefs, 2]);
    dist_prefs = zeros(1, 1);
    audio_prefs = zeros(1, 1);
    neuron_cols = [];
    network_ids = 0;
    da_rew_neurons = [];
    neuron_tones = [];
    network = struct; % this will need its subdivisions in design mode
    network_drive = zeros(1, 3);
    nnetworks = 0;
    bg_neurons = [];

    if brain_gen
        brain_gen_build_7
        neuron_scripts = zeros(nneurons, 1);
    end
end
