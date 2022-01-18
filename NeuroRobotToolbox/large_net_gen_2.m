

%% Brain to append as CPG / BG net
brain_name_2 = popup_select_brain.String{popup_select_brain.Value};

%% Load brain 2
load(strcat('./Brains/', brain_name_2, '.mat'))
nneurons_2 = brain.nneurons;
neuron_xys_2 = brain.neuron_xys;
connectome_2 = brain.connectome;
% da_connectome_2 = brain.da_connectome;
% if size(da_connectome_2, 3) == 2
%     da_connectome_2(:,:,3) = zeros(size(connectome_2));
% end
a_init_2 = brain.a_init;
b_init_2 = brain.b_init;
c_init_2 = brain.c_init;
d_init_2 = brain.d_init;
w_init_2 = brain.w_init;
a_2 = brain.a;
b_2 = brain.b;
c_2 = brain.c;
d_2 = brain.d;
v_2 = c_2 + 5 * randn(nneurons_2, 1);
u_2 = b_2 .* v_2;
neuron_contacts_2 = brain.neuron_contacts;
vis_prefs_2 = brain.vis_prefs;
dist_prefs_2 = brain.dist_prefs;
try
    audio_prefs_2 = brain.audio_prefs;
catch
    audio_prefs_2 = zeros(nneurons_2, 1);
end
neuron_cols_2 = brain.neuron_cols;
network_ids_2 = brain.network_ids;
da_rew_neurons_2 = brain.da_rew_neurons;
try
    neuron_tones_2 = brain.neuron_tones;
catch
    neuron_tones_2 = zeros(nneurons_2, 1);
end
neuron_scripts_2 = brain.neuron_scripts;
nnetworks_2 = length(unique(network_ids_2)); % There used to be a +1 hack here, removing, testing..
try
    network_2 = brain.network;
catch
    for nnetwork = 1:nnetworks_2
        network_2(nnetwork).null = []; % Does this even have to be initialized?
    end
end
try
    network_drive_2 = brain.network_drive;
    if isempty(network_drive_2) || size(network_drive_2, 1) < nnetwork_2 || size(network_drive_2, 2) == 2
        network_drive_2 = zeros(nnetworks_2, 3); 
    end
catch
    network_drive_2 = zeros(nnetworks_2, 3); 
end
try
    bg_neurons_2 = brain.bg_neurons;
catch
    bg_neurons_2 = zeros(nneurons_2, 1);
end

%% Get new XYs
n = nneurons_2;
xx = 0.001 * n + 0.25;
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
    neuron_xys_2(nneuron, :) = xys + mouse_location(1,1:2);
end

%% Merge brains
nneurons = nneurons + nneurons_2;
neuron_xys = [neuron_xys; neuron_xys_2];

% % space evenly
% load('brain_im_xy')
% imx_rands = randsample(length(brain_im_xy), brain.nneurons); 
% brain.neuron_xys = brain_im_xy(imx_rands, :);

% this matrix tiling may not work right!
connectome = [connectome zeros(size(connectome, 1), size(connectome_2, 1)); zeros(size(connectome_2, 1), size(connectome, 1)) connectome_2];

% here tiling definitely doesn't work yet, starting from zero
da_connectome = zeros(nneurons, nneurons, 3);
% for ii = 1:3
%     da_connectome(:,:,ii) = [da_connectome(:,:,ii) zeros(size(da_connectome(:,:,ii), 1)); zeros(size(da_connectome_2(:,:,ii), 1)) da_connectome_2(:,:,ii)];
% end

spikes_loop = zeros(nneurons, ms_per_step * nsteps_per_loop);

% a_init = a_init_1;
% b_init = b_init_1;
% c_init = c_init_1;
% d_init = d_init_1;
% w_init = w_init_1;

a = [a; a_2];
b = [b; b_2];
c = [c; c_2];
d = [d; d_2];
v = [v; v_2];
u = [u; u_2];
neuron_contacts = [neuron_contacts; neuron_contacts_2];

% Fix to correct for changing # of visual features
% Note: Older brains will get visual miswiring
vis_diff = diff([size(vis_prefs, 2) size(vis_prefs_2, 2)]);
if vis_diff < 0
    vis_prefs_2(:,end+1:end-vis_diff, :) = 0;
elseif vis_diff > 0
    vis_prefs(:,end+1:end+vis_diff, :) = 0;
end

vis_prefs = [vis_prefs; vis_prefs_2];
audio_prefs = [audio_prefs; audio_prefs_2];
dist_prefs = [dist_prefs; dist_prefs_2];
neuron_cols = [neuron_cols; neuron_cols_2];

network_ids_2 = network_ids_2 + max([max(network_ids) 1]);
network_ids = [network_ids; network_ids_2];
nnetworks = length(unique(network_ids));
network_drive = zeros(nnetworks, 3);
network_colors = linspecer(length(unique(network_ids)));

da_rew_neurons = [da_rew_neurons; da_rew_neurons_2];
neuron_tones = [neuron_tones; neuron_tones_2];
neuron_scripts = [neuron_scripts; neuron_scripts_2];
network = [network; network_2]; % Not sure if this works
bg_neurons = [bg_neurons; bg_neurons_2];

steps_since_last_spike = nan(nneurons, 1); % this resets

disp('Large network created')