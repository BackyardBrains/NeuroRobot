

if length(cnet_temp) == 1
    this_fix = 0.85;
else
    this_fix = 0;
end
presyn = [];
postsyn = [];

%% Create state net
n = n_vis_prefs - n_basic_vis_features;

% Get equally distributed points
% xx = 0.005 * n + 0.4;
% npoints = round(2*sqrt(n));
% phi = (sqrt(5)+1)/2;
for nneuron = 1:n
%     if nneuron > n - npoints
%         r = 1;
%     else
%         r = sqrt(nneuron-1/2)/sqrt(n-(npoints+1)/2);
%     end
%     theta = 2*pi*nneuron/phi^2;
%     xys = [r*cos(theta), r*sin(theta)];
%     xys = xys * xx;
%     xys(:,2) = xys(:,2) + this_fix;
    xys = [-0.5 ((nneuron/n)-0.5)*3];
    neuron_xys(nneurons + nneuron, :) = xys + mouse_location(1,1:2);
end

% Update parameters
if use_cnn
    counter = n_basic_vis_features + 13;
else
    counter = n_basic_vis_features;
end
for presynaptic_neuron = nneurons + 1:nneurons + n

    counter = counter + 1;
    presyn = [presyn presynaptic_neuron];

    % Neuron-neuron synapses
    for postsynaptic_neuron = nneurons + 1:nneurons + n
        connectome(presynaptic_neuron, postsynaptic_neuron) = 0;
        da_connectome(presynaptic_neuron, postsynaptic_neuron, 1:3) = 0;
    end

    % Sensory input
    neuron_contacts(presynaptic_neuron, [1 2]) = 1;
    vis_prefs(presynaptic_neuron, counter, :) = 1;
    dist_prefs(presynaptic_neuron, 1) = 0;
    audio_prefs(presynaptic_neuron, 1) = 0;
    bg_neurons(presynaptic_neuron, 1) = 0;

    % Motor output
    neuron_contacts(presynaptic_neuron, 6:13) = 0;
end

% Other variables
spikes_loop = zeros(nneurons + n, ms_per_step * nsteps_per_loop);
a(nneurons + 1 : nneurons + n, 1) = a_init;
b(nneurons + 1 : nneurons + n, 1) = b_init;
c(nneurons + 1 : nneurons + n, 1) = c_init;
d(nneurons + 1 : nneurons + n, 1) = d_init;
v(nneurons + 1 : nneurons + n, 1) = c_init + 5 * randn(n,1);
u = b .* v;
network_ids(nneurons + 1 : nneurons + n, 1) = 1;
nnetworks = length(unique(network_ids));
network_drive = zeros(nnetworks, 3);

if bg_colors
    neuron_cols(nneurons + 1 : nneurons + n, 1:3) = repmat([1 0.9 0.8], [n, 1]);
end

da_rew_neurons(nneurons + 1 : nneurons + n, 1) = 0;
steps_since_last_spike(nneurons + 1 : nneurons + n) = nan;
neuron_tones(nneurons + 1 : nneurons + n, 1) = 0;
neuron_scripts(nneurons + 1 : nneurons + n, 1) = 0;
nneurons = nneurons + n;


%% Create action net
if length(cnet_temp) >= 1

    n = n_unique_actions;

    % Get equally distributed points
%     xx = 0.005 * n + 0.4;
%     npoints = round(2*sqrt(n));
%     phi = (sqrt(5)+1)/2;
    for nneuron = 1:n
%         if nneuron > n - npoints
%             r = 1;
%         else
%             r = sqrt(nneuron-1/2)/sqrt(n-(npoints+1)/2);
%         end
%         theta = 2*pi*nneuron/phi^2;
%         xys = [r*cos(theta), r*sin(theta)];
%         xys = xys * xx;
%         xys(:,2) = xys(:,2) - this_fix;
        xys = [0.5 ((nneuron/n)-0.5)*3];
        neuron_xys(nneurons + nneuron, :) = xys + mouse_location(1,1:2);
    end

    % Update parameters
    counter = 0;
    moto(1).contacts = 8; % Left forward
    moto(2).contacts = 9; % Left backward
    moto(3).contacts = 12; % Right forward
    moto(4).contacts = 13; % Right backward    
    for presynaptic_neuron = nneurons + 1:nneurons + n

        counter = counter + 1;
        postsyn = [postsyn presynaptic_neuron];

        % Neuron-neuron synapses
        for postsynaptic_neuron = nneurons + 1:nneurons + n
            connectome(presynaptic_neuron, postsynaptic_neuron) = 0;
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 1:3) = 0;
        end

        % Sensory input
        neuron_contacts(presynaptic_neuron, [1 2]) = 0;
        vis_prefs(presynaptic_neuron, :, :) = 0;
        dist_prefs(presynaptic_neuron, 1) = 0;
        audio_prefs(presynaptic_neuron, 1) = 0;
        bg_neurons(presynaptic_neuron, 1) = 0;

        % Motor output
        mout = motor_combs(counter, :);
        if mout(1) >= 0
            neuron_contacts(presynaptic_neuron, moto(1).contacts) = mout(1);
        else
            neuron_contacts(presynaptic_neuron, moto(2).contacts) = -mout(1);
        end
        if mout(2) >= 0
            neuron_contacts(presynaptic_neuron, moto(3).contacts) = mout(2);
        else
            neuron_contacts(presynaptic_neuron, moto(4).contacts) = -mout(2);
        end        
    end

    % Other variables
    spikes_loop = zeros(nneurons + n, ms_per_step * nsteps_per_loop);
    a(nneurons + 1 : nneurons + n, 1) = a_init;
    b(nneurons + 1 : nneurons + n, 1) = b_init;
    c(nneurons + 1 : nneurons + n, 1) = c_init;
    d(nneurons + 1 : nneurons + n, 1) = d_init;
    v(nneurons + 1 : nneurons + n, 1) = c_init + 5 * randn(n,1);
    u = b .* v;
    network_ids(nneurons + 1 : nneurons + n, 1) = 1;
    nnetworks = length(unique(network_ids));
    network_drive = zeros(nnetworks, 3);

    if bg_colors
        neuron_cols(nneurons + 1 : nneurons + n, 1:3) = repmat([1 0.9 0.8], [n, 1]);
    end

    da_rew_neurons(nneurons + 1 : nneurons + n, 1) = 0;
    steps_since_last_spike(nneurons + 1 : nneurons + n) = nan;
    neuron_tones(nneurons + 1 : nneurons + n, 1) = 0;
    neuron_scripts(nneurons + 1 : nneurons + n, 1) = 0;
    nneurons = nneurons + n;

    counter = 0;
    for ii = presyn
        counter = counter + 1;
        this_action = getAction(agent, counter);
        this_action = cell2mat(this_action);
        this_neuron = postsyn(this_action);
        connectome(ii, this_neuron) = 15;
    end
end

disp('Network created')

