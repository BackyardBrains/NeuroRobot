
new_brain_vars

nneurons = 5;

neuron_xys = [   -0.6294    0.8139
    0.6154    0.8328
   -0.7366   -1.0284
    0.8159   -1.0158
    0.0093   -1.0221];

% % Get equally distributed points
% xx = 0.001 * n + 0.7;
% npoints = round(2*sqrt(n));
% phi = (sqrt(5)+1)/2;
% for nneuron = 1:n
%     if nneuron > n - npoints
%         r = 1;
%     else
%         r = sqrt(nneuron-1/2)/sqrt(n-(npoints+1)/2);
%     end
%     theta = 2*pi*nneuron/phi^2;
%     xys = [r*cos(theta), r*sin(theta)];
%     xys = xys * xx;
%     neuron_xys(nneurons + nneuron, :) = xys + mouse_location(1,1:2);
% end

% Update parameters
for presynaptic_neuron = 1:nneurons

    % Neuron-neuron synapses
    for postsynaptic_neuron = 1:nneurons
        connected = rand <= 0.3;
        weight = randsample(-100:25:100, 1) / 10;
        connectome(presynaptic_neuron, postsynaptic_neuron) = connected * weight;
        da_connectome(presynaptic_neuron, postsynaptic_neuron, 1) = 0;
        da_connectome(presynaptic_neuron, postsynaptic_neuron, 2) = connected * weight;
        da_connectome(presynaptic_neuron, postsynaptic_neuron, 3) = 0;
    end

    % Sensory input
    sens_neuron = rand <= 0.3;
    this_contact = randsample(2,1);
    
    if sens_neuron
        this_val = 1;
    else
        this_val = 0;
    end
    neuron_contacts(presynaptic_neuron, this_contact) = this_val * 100;
    vis_prefs(presynaptic_neuron, randsample(3,1), this_contact) = this_val;

    dist_neuron = rand <= 0.3;
    if sens_neuron
        this_val = 1;
    else
        this_val = 0;
    end

    dist_prefs(presynaptic_neuron, 1) = this_val * 3;
    neuron_contacts(presynaptic_neuron, 5) = this_val;

    audio_prefs(presynaptic_neuron, 1) = 0;
    bg_neurons(presynaptic_neuron, 1) = 0;

    % Motor output
    moto_neuron = rand <= 0.5;
    if moto_neuron
        this_val = 1;
    else
        this_val = 0;
    end    
    m_val = randsample(4,1);
    m_force = randsample(-250:50:250,1);
    moto(1).contacts = 8; % Left forward
    moto(2).contacts = 9; % Left backward
    moto(3).contacts = 12; % Right forward
    moto(4).contacts = 13; % Right backward      
    neuron_contacts(presynaptic_neuron, moto(m_val).contacts) = this_val * m_force;
end

% Other variables
spikes_loop = zeros(nneurons, ms_per_step * nsteps_per_loop);
a(1:nneurons, 1) = a_init;
b(1:nneurons, 1) = randsample(0.1:0.02:2, nneurons);
c(1:nneurons, 1) = randsample(-100:5:0, nneurons);
d(1:nneurons, 1) = d_init;
v(1:nneurons, 1) = c_init + 5 * randn(nneurons,1);
u = b .* v;
network_ids(1:nneurons, 1) = 1;
nnetworks = length(unique(network_ids));
network_drive = zeros(nnetworks, 3);

b1 = b - min(b);
b1 = b1 / max(b1);
bx = (1 - b1) .* 0.5;
b1 = b1 + bx;

c1 = c - min(c);
c1 = c1 / max(c1);
cx = (1 - c1) .* 0.5;
c1 = c1 + cx;

if bg_colors
    neuron_cols(1:nneurons, 1:3) = [b1 c1 c1];
end

da_rew_neurons(1:nneurons, 1) = 0;
steps_since_last_spike(1:nneurons) = nan;
neuron_tones(1:nneurons, 1) = 0;
neuron_scripts(1:nneurons, 1) = 0;
delays(1:nneurons, 1) = 0;
counters(1:nneurons, 1) = 0;

disp('Randomized brain created')

delete(text_heading)
delete(text_w1)
delete(edit_w1)
delete(text_w2)
delete(edit_w2)
delete(text_w3)
delete(edit_w3)
delete(text_w4)
delete(edit_w4)
delete(text_w5)
delete(edit_w5)
delete(text_w6)
delete(edit_w6)
delete(text_id)
delete(edit_id)
