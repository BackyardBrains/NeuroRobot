
nneurons = brain.nneurons;
neuron_xys = brain.neuron_xys;
connectome = brain.connectome;
da_connectome = brain.da_connectome;
neuron_contacts = brain.neuron_contacts;
vis_prefs = brain.vis_prefs;
dist_prefs = brain.dist_prefs;
try
    audio_prefs = brain.audio_prefs;
catch
    audio_prefs = zeros(nneurons, 1);
end
neuron_cols = brain.neuron_cols;
network_ids = brain.network_ids;
da_rew_neurons = brain.da_rew_neurons;
try
    neuron_tones = brain.neuron_tones;
catch
    neuron_tones = zeros(nneurons, 1);
end
nnetworks = length(unique(network_ids)) + 1;
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
% down_neurons = false(nneurons, 1);
