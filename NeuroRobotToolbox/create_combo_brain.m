

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

da_rew_neurons = [da_rew_neurons; da_rew_neurons_2];
neuron_tones = [neuron_tones; neuron_tones_2];
neuron_scripts = [neuron_scripts; neuron_scripts_2];
% network = [network; network_2]; % Not sure if this works
bg_neurons = [bg_neurons; bg_neurons_2];

steps_since_last_spike = nan(nneurons, 1); % this resets

disp('Brain imported')

