
if ~isempty(brain_edit_name.String)
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
    neuron_scripts = [];
    brain_name = brain_edit_name.String;
else
    brain_edit_name.BackgroundColor = [1 0.25 0.25];
    pause(0.75)
    brain_edit_name.BackgroundColor = [0.94 0.94 0.94];
end