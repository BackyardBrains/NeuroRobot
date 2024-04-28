

brain_name = available_brains(nbrain).name;
load(horzcat(brain_dir, brain_name))

nneurons = brain.nneurons;
neuron_xys = brain.neuron_xys;
neuron_cols = brain.neuron_cols;
connectome = brain.connectome;
try
    da_connectome = brain.da_connectome;
catch
    da_connectome = [];
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

try
    neuron_contacts = brain.neuron_contacts;
catch
    neuron_contacts = [];
end
vis_prefs = brain.vis_prefs;
try
    dist_prefs = brain.dist_prefs;
catch
    dist_prefs = [];
end
try
    audio_prefs = brain.audio_prefs;
catch
    audio_prefs = [];
end
try
    network_ids = brain.network_ids;
catch
    network_ids = [];
end

try
    da_rew_neurons = brain.da_rew_neurons;
catch
    da_rew_neurons = [];
end
try
    neuron_tones = brain.neuron_tones;
catch
    neuron_tones = [];
end

try
    neuron_scripts = brain.neuron_scripts;
catch
    neuron_scripts = [];
end
nnetworks = length(unique(network_ids)); % There used to be a +1 hack here, removing, testing..

try
    network_drive = zeros(nnetworks, 3); 
catch
    network_drive = [];
end
try
    bg_neurons = brain.bg_neurons;
catch
    bg_neurons = [];
end
try
    trained_nets = brain.trained_nets;
catch
    trained_nets = cell(1);
end

