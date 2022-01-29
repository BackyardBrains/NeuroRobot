%% Load or initialize brain
if brain_selection_val > 1
    load(strcat('./Brains/', load_name, '.mat'))
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
    
%     u = b' .* v; % HACK 2020-12-20 (')
    u = b .* v; % original (')    
    
    spikes_loop = zeros(nneurons, ms_per_step * nsteps_per_loop);
    if isfield(brain, 'spikes_loop')
        brain = rmfield(brain, 'spikes_loop');
    end
    neuron_contacts = brain.neuron_contacts;
    vis_prefs = brain.vis_prefs;
    dist_prefs = brain.dist_prefs;
    try
        audio_prefs = brain.audio_prefs;
    catch
        audio_prefs = zeros(nneurons, 1);
    end
%     neuron_cols = brain.neuron_cols;
    network_ids = brain.network_ids;
    
    if bg_colors
        network_colors = linspecer(length(unique(network_ids)));
        network_colors(1, :) = [1 0.9 0.8];
    end
    
    da_rew_neurons = brain.da_rew_neurons;
    try
        neuron_tones = brain.neuron_tones;
    catch
        neuron_tones = zeros(nneurons, 1);
    end
    try
        neuron_scripts = brain.neuron_scripts;
    catch
        neuron_scripts = zeros(nneurons, 1);
    end
    nnetworks = length(unique(network_ids)); % There used to be a +1 hack here, removing, testing..
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
    try
            % Ability to add custom words here. NOW
    if isfield('brain', 'audio_out_wavs')
        
    end
    
%         this_word = vis_pref_names{nsound};
%         this_wav = tts(this_word,[],[],16000);
%         this_wav = this_wav(find(this_wav,1,'first'):find(this_wav,1,'last'));
%         audio_out_durations = [audio_out_durations length(this_wav)/16000];
%         audio_out_wavs(n_out_sounds + nsound).y = this_wav;
%         audio_out_fs(n_out_sounds + nsound) = 16000;     
        
    catch
    end    
%     for nsound = 1:n_vis_prefs
%         this_word = vis_pref_names{nsound};
%         this_wav = tts(this_word,[],[],16000);
%         this_wav = this_wav(find(this_wav,1,'first'):find(this_wav,1,'last'));
%         audio_out_durations = [audio_out_durations length(this_wav)/16000];
%         audio_out_wavs(n_out_sounds + nsound).y = this_wav;
%         audio_out_fs(n_out_sounds + nsound) = 16000;        
%     end
%     
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
%         brain_gen_build_1
%         brain_gen_build_5
%         brain_gen_build_7
%         brain_gen_build_11
%         brain_gen_build_13
%         brain_gen_build_14
        brain_gen_build_15
    end
end
