


% Get number of neurons in the network
n = str2double(edit_w1.String);
if n > 10000
    n = 10000;
    disp('Network size reduced to 10000 neurons')
end

% Get equally distributed points
xx = 0.001 * n + 0.3;
npoints = round(2*sqrt(n));
phi = (sqrt(5)+1)/2;
for nneuron = 1:n
    if nneuron > n - npoints
        r = 1;
    else
        r = sqrt(nneuron-1/2)/sqrt(n-(npoints+1)/2);
    end
    theta = 2*pi*nneuron/phi^2;
    xys = [r*cos(theta), r*sin(theta)];
    xys = xys * xx;
    neuron_xys(nneurons + nneuron, :) = xys + mouse_location(1,1:2);
end

% Update parameters
for presynaptic_neuron = nneurons + 1:nneurons + n

    % Neuron-neuron synapses
    for postsynaptic_neuron = nneurons + 1:nneurons + n
        connected = rand <= str2double(edit_w2.String) / 100;
        connected = connected * sign(rand-0.3);
        %                     synapse_sign = sign((rand < str2double(edit_w3.String)) - 0.5);
        weight = str2double(edit_w3.String);
        connectome(presynaptic_neuron, postsynaptic_neuron) = connected * weight;
        da_connectome(presynaptic_neuron, postsynaptic_neuron, 1) = rand <= str2double(edit_w4.String) / 100;
        da_connectome(presynaptic_neuron, postsynaptic_neuron, 2) = connected * weight;
        da_connectome(presynaptic_neuron, postsynaptic_neuron, 3) = 0;
    end

    % Sensory input
    sens_neuron = rand <= str2double(edit_w5.String) / 100;
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
    moto_neuron = rand <= str2double(edit_w6.String) / 100;
    m_val = randsample(4,1);
    moto(1).contacts = [6, 8];
    moto(2).contacts = [7, 9];
    moto(3).contacts = [10, 12];
    moto(4).contacts = [11, 13];
    neuron_contacts(presynaptic_neuron, moto(m_val).contacts) = moto_neuron * 250;
end

% Other variables
spikes_loop = zeros(nneurons + n, ms_per_step * nsteps_per_loop);
a(nneurons + 1 : nneurons + n, 1) = a_init;
b(nneurons + 1 : nneurons + n, 1) = b_init;
c(nneurons + 1 : nneurons + n, 1) = c_init;
d(nneurons + 1 : nneurons + n, 1) = d_init;
v(nneurons + 1 : nneurons + n, 1) = c_init + 5 * randn(n,1);
u = b .* v;
network_ids(nneurons + 1 : nneurons + n, 1) = str2double(edit_id.String);
nnetworks = length(unique(network_ids));
network_drive = zeros(nnetworks, 3);

if bg_colors
    if nnetworks > size(network_colors, 1)
        network_colors = linspecer(length(unique(network_ids)));
    end
    neuron_cols(nneurons + 1 : nneurons + n, 1:3) = repmat([1 0.9 0.8], [n, 1]);
end

da_rew_neurons(nneurons + 1 : nneurons + n, 1) = 0;
steps_since_last_spike(nneurons + 1 : nneurons + n) = nan;
neuron_tones(nneurons + 1 : nneurons + n, 1) = 0;
neuron_scripts(nneurons + 1 : nneurons + n, 1) = 0;
nneurons = nneurons + n;
if ext_cam_id
    save_firing = zeros(nneurons, ext_cam_nsteps, 'logical');
end
disp('Population created')

