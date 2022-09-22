



%% Settings
nneurons_2 = 20;


%% Prepare
a_2 = 0.02 * ones(nneurons_2,1);
b_2 = 0.13 * ones(nneurons_2,1);
c_2 = -65 + 5 * rand(nneurons_2,1) .^ 2;
d_2 = 8 - 6 * rand(nneurons_2,1) .^ 2;
connectome_2 = zeros(nneurons_2);
v_2 = -65 + 5 * rand(nneurons_2,1) .^ 2;
u_2 = b_2 .* v_2;
brain = struct;
neuron_contacts_2 = zeros(nneurons_2, 13);
vis_prefs_2 = zeros(nneurons_2, 23, 2);
dist_prefs_2 = zeros(nneurons_2, 1);
audio_prefs_2 = zeros(nneurons_2, 1);
network_ids_2 = ones(nneurons_2, 1);
da_rew_neurons_2 = zeros(nneurons_2, 1);
neuron_tones_2 = zeros(nneurons_2, 1);
bg_neurons_2 = zeros(nneurons_2, 1);
da_connectome_2 = zeros(nneurons_2, nneurons_2, 3);
neuron_cols_2 = repmat([1 0.9 0.8], [nneurons_2, 1]);
network_2 = struct;
nnetworks_2 = length(unique(network_ids));
network_drive_2 = zeros(nnetworks_2, 3);
spikes_loop_2 = zeros(nneurons_2, ms_per_step * nsteps_per_loop);
% neuron_xys = zeros(nneurons, 2);
neuron_scripts_2 = zeros(nneurons_2, 1);


%% Anatomy
% xrange = linspace(-1.5, 1.5, sqrt(nneurons_2));
% yrange = linspace(1.3, -1.7, sqrt(nneurons_2));
% [xg,yg] = meshgrid(xrange,yrange);
% counter = 0;
% for nx = 1:sqrt(nneurons_2)
%     for ny = 1:sqrt(nneurons_2)
%         counter = counter + 1;
%         neuron_xys_2(counter, :) = [xg(nx, ny), yg(nx, ny)];
%     end
% end

imx_rands = randsample(length(brain_im_xy), nneurons_2); 
neuron_xys_2 = brain_im_xy(imx_rands, :) * 0.5;

for presynaptic_neuron = 1:nneurons_2
    
    % Connectome
    for postsynaptic_neuron = 1:nneurons_2
        
%         if rand < 0.05
            
            % Euclidian distance between neurons
            this_weight = 0;
            xe = abs(neuron_xys_2(presynaptic_neuron, 1) - neuron_xys_2(postsynaptic_neuron, 1));
            ye = abs(neuron_xys_2(presynaptic_neuron, 2) - neuron_xys_2(postsynaptic_neuron, 2));
            ce = sqrt(xe^2 + ye^2);
                   
            if ce <= 0.12 && rand < 0.4
                this_weight = 85 * rand;
            elseif ce < 0.22 && rand < 0.2
                this_weight = -85 * rand;
            end
            connectome_2(presynaptic_neuron, postsynaptic_neuron) = this_weight;
            da_connectome_2(presynaptic_neuron, postsynaptic_neuron, 1) = 0;
            da_connectome_2(presynaptic_neuron, postsynaptic_neuron, 2) = this_weight;   
            da_connectome_2(presynaptic_neuron, postsynaptic_neuron, 3) = 0;      

            connectome_2(postsynaptic_neuron, presynaptic_neuron) = this_weight;
            da_connectome_2(postsynaptic_neuron, presynaptic_neuron, 1) = 0;
            da_connectome_2(postsynaptic_neuron, presynaptic_neuron, 2) = this_weight;   
            da_connectome_2(postsynaptic_neuron, presynaptic_neuron, 3) = 0;      
            
    end
    
%     % Visual input
%     if abs(0 - neuron_xys(presynaptic_neuron, 1)) < 0.3 && ...
%             abs(-0.2 - neuron_xys(presynaptic_neuron, 2)) < 0.3
%         this_contact = randsample(2,1);
%         neuron_contacts(presynaptic_neuron, this_contact) = 1;
%         vis_prefs(presynaptic_neuron, randsample(3,1), this_contact) = 1;
%         neuron_contacts(presynaptic_neuron, 3) = 1;
%         audio_prefs(presynaptic_neuron) = round(rand * 2000);
%     end
    
%     % Auditory input
%     if rand < 0.1
%         neuron_contacts(presynaptic_neuron, 3) = 1;
%         audio_prefs(presynaptic_neuron) = round(rand * 2000);
%     end
    
end


