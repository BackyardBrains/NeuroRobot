
nneurons = brain.nneurons;
neuron_xys = brain.neuron_xys;
neuron_cols = brain.neuron_cols;
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

da_rew_neurons = brain.da_rew_neurons;
neuron_tones = brain.neuron_tones;
neuron_scripts = brain.neuron_scripts;
nnetworks = length(unique(network_ids)); % There used to be a +1 hack here, removing, testing..

network_drive = zeros(nnetworks, 3); 
bg_neurons = brain.bg_neurons;

trained_nets = brain.trained_nets;
if isempty(trained_nets)
    trained_nets = cell(1);
end


