% The purpose of this script is to allow merging of two brains.
% I need this to merge Beix and Jah to create Morpheus.

close all
clear

%% Brains to merge
brain_name_1 = 'Jah';
brain_name_2 = 'Beix';
output_name = 'Morpheus';

%% Load brain 1
load(strcat('./Brains/', brain_name_1, '.mat'))
nneurons_1 = brain.nneurons;
neuron_xys_1 = brain.neuron_xys;
connectome_1 = brain.connectome;
da_connectome_1 = brain.da_connectome;
if size(da_connectome_1, 3) == 2
    da_connectome_1(:,:,3) = zeros(size(connectome_1));
end
a_init_1 = brain.a_init;
b_init_1 = brain.b_init;
c_init_1 = brain.c_init;
d_init_1 = brain.d_init;
w_init_1 = brain.w_init;
a_1 = brain.a;
b_1 = brain.b;
c_1 = brain.c;
d_1 = brain.d;
v_1 = c_1 + 5 * randn(nneurons_1, 1);
u_1 = b_1 .* v_1;
neuron_contacts_1 = brain.neuron_contacts;
vis_prefs_1 = brain.vis_prefs;
dist_prefs_1 = brain.dist_prefs;
try
    audio_prefs_1 = brain.audio_prefs;
catch
    audio_prefs_1 = zeros(nneurons_1, 1);
end
neuron_cols_1 = brain.neuron_cols;
network_ids_1 = brain.network_ids;
da_rew_neurons_1 = brain.da_rew_neurons;
try
    neuron_tones_1 = brain.neuron_tones;
catch
    neuron_tones_1 = zeros(nneurons_1, 1);
end
nnetworks_1 = length(unique(network_ids_1)); % There used to be a +1 hack here, removing, testing..
try
    network_1 = brain.network;
catch
    for nnetwork = 1:nnetworks_1
        network_1(nnetwork).null = []; % Does this even have to be initialized?
    end
end
try
    network_drive_1 = brain.network_drive;
    if isempty(network_drive_1) || size(network_drive_1, 1) < nnetworks_1 || size(network_drive_1, 2) == 2
        network_drive_1 = zeros(nnetworks_1, 3); 
    end
catch
    network_drive_1 = zeros(nnetworks_1, 3); 
end
try
    bg_neurons_1 = brain.bg_neurons;
catch
    bg_neurons_1 = zeros(nneurons_1, 1);
end
    
%% Load brain 2
load(strcat('./Brains/', brain_name_2, '.mat'))
nneurons_2 = brain.nneurons;
neuron_xys_2 = brain.neuron_xys;
connectome_2 = brain.connectome;
da_connectome_2 = brain.da_connectome;
if size(da_connectome_2, 3) == 2
    da_connectome_2(:,:,3) = zeros(size(connectome_2));
end
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

%% Merge brains
clear brain
brain.nneurons = nneurons_1 + nneurons_2;
brain.neuron_xys = [neuron_xys_1; neuron_xys_2];

% % space evenly
% load('brain_im_xy')
% imx_rands = randsample(length(brain_im_xy), brain.nneurons); 
% brain.neuron_xys = brain_im_xy(imx_rands, :);


brain.connectome = [connectome_1 zeros(size(connectome_1)); zeros(size(connectome_2)) connectome_2];
for ii = 1:3
    brain.da_connectome(:,:,ii) = [da_connectome_1(:,:,ii) zeros(size(da_connectome_1(:,:,ii))); zeros(size(da_connectome_2(:,:,ii))) da_connectome_2(:,:,ii)];
end
brain.a_init = a_init_1;
brain.b_init = b_init_1;
brain.c_init = c_init_1;
brain.d_init = d_init_1;
brain.w_init = w_init_1;
brain.a = [a_1; a_2];
brain.b = [b_1; b_2];
brain.c = [c_1; c_2];
brain.d = [d_1; d_2];
brain.v = [v_1; v_2];
brain.u = [u_1; u_2];
brain.neuron_contacts = [neuron_contacts_1; neuron_contacts_2];
for ii = 1:2
    brain.vis_prefs(:,:,ii) = [vis_prefs_1(:,:,ii); vis_prefs_2(:,:,ii)];
end
brain.audio_prefs = [audio_prefs_1; audio_prefs_2];
brain.dist_prefs = [dist_prefs_1; dist_prefs_2];
brain.neuron_cols = [neuron_cols_1; neuron_cols_2];
brain.network_ids = [network_ids_1; network_ids_2];
brain.da_rew_neurons = [da_rew_neurons_1; da_rew_neurons_2];
brain.neuron_tones = [neuron_tones_1; neuron_tones_2];
brain.network_drive = [network_drive_1; network_drive_2];
brain.network = [network_1; network_2]; % Not sure if this works
brain.bg_neurons = [bg_neurons_1; bg_neurons_2];

%% Save new brain
brain_name = output_name;
brain_file_name = strcat('./Brains/', brain_name, '.mat');
save(brain_file_name, 'brain')
