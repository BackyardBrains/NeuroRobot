

%% Settings
nneurons = 250;


%% Prepare
a = 0.02 * ones(nneurons,1);
b = 0.13 * ones(nneurons,1);
c = -65 + 5 * rand(nneurons,1) .^ 2;
d = 8 - 6 * rand(nneurons,1) .^ 2;
connectome = zeros(nneurons);
v = -65 + 5 * rand(nneurons,1) .^ 2;
u = b .* v;
brain = struct;
neuron_contacts = zeros(nneurons, 13);
vis_prefs = zeros(nneurons, 23, 2);
dist_prefs = zeros(nneurons, 1);
audio_prefs = zeros(nneurons, 1);
network_ids = ones(nneurons, 1);
da_rew_neurons = zeros(nneurons, 1);
neuron_tones = zeros(nneurons, 1);
bg_neurons = zeros(nneurons, 1);
da_connectome = zeros(nneurons, nneurons, 3);
neuron_cols = repmat([1 0.9 0.8], [nneurons, 1]);
steps_since_last_spike(1:nneurons) = nan;
network = struct;
nnetworks = length(unique(network_ids));
network_drive = zeros(nnetworks, 3);
spikes_loop = zeros(nneurons, ms_per_step * nsteps_per_loop);
% neuron_xys = zeros(nneurons, 2);
neuron_scripts = zeros(nneurons, 1);


%% Anatomy
% xrange = linspace(-1.5, 1.5, sqrt(nneurons));
% yrange = linspace(1.3, -1.7, sqrt(nneurons));
% [xg,yg] = meshgrid(xrange,yrange);
% counter = 0;
% for nx = 1:sqrt(nneurons)
%     for ny = 1:sqrt(nneurons)
%         counter = counter + 1;
%         neuron_xys(counter, :) = [xg(nx, ny), yg(nx, ny)];
%     end
% end

imx_rands = randsample(length(brain_im_xy), nneurons); 
neuron_xys = brain_im_xy(imx_rands, :);
neuron_xys = neuron_xys * 0.8;
for presynaptic_neuron = 1:nneurons
    
    % Connectome
    for postsynaptic_neuron = 1:nneurons
        
%         if rand < 0.05
            
            % Euclidian distance between neurons
            this_weight = 0;
            xe = abs(neuron_xys(presynaptic_neuron, 1) - neuron_xys(postsynaptic_neuron, 1));
            ye = abs(neuron_xys(presynaptic_neuron, 2) - neuron_xys(postsynaptic_neuron, 2));
            ce = sqrt(xe^2 + ye^2);
            
            
                   
            if ce > 0.1 && ce <= 0.4 && rand < 0.2
                this_weight = 10 * rand;
%             elseif ce < 0.2 && rand < 0.66
%                 this_weight = 50 * rand;
            end
            
            connectome(presynaptic_neuron, postsynaptic_neuron) = this_weight;
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 1) = 2;
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 2) = this_weight;   
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 3) = 0;      

            if this_weight
                connectome(postsynaptic_neuron, presynaptic_neuron) = 100 - this_weight;
                da_connectome(postsynaptic_neuron, presynaptic_neuron, 1) = 2;
                da_connectome(postsynaptic_neuron, presynaptic_neuron, 2) = 100 - this_weight;   
                da_connectome(postsynaptic_neuron, presynaptic_neuron, 3) = 0;
            end
            
    end
    
    
    if rand < 0.2
        neuron_contacts(presynaptic_neuron, 4) = 1;
%         vis_prefs(presynaptic_neuron, 1, 1) = 1;
        neuron_tones(presynaptic_neuron, 1) = 500 + round(rand * 500);
%         da_rew_neurons(presynaptic_neuron, 1) = 1;
    end
    
%     % Visual input
%     if abs(-0.5 - neuron_xys(presynaptic_neuron, 1)) < 0.3 && ...
%             abs(1 - neuron_xys(presynaptic_neuron, 2)) < 0.3
%         this_contact = randsample(2,1);
%         neuron_contacts(presynaptic_neuron, this_contact) = 1;
%         vis_prefs(presynaptic_neuron, 1, this_contact) = 1;
%     elseif abs(0.5 - neuron_xys(presynaptic_neuron, 1)) < 0.3 && ...
%             abs(1 - neuron_xys(presynaptic_neuron, 2)) < 0.3
%         this_contact = randsample(2,1);
%         neuron_contacts(presynaptic_neuron, this_contact) = 1;
%         vis_prefs(presynaptic_neuron, 3, this_contact) = 1;
% %         neuron_contacts(presynaptic_neuron, 3) = 1;
% %         audio_prefs(presynaptic_neuron) = round(rand * 2000);
%     end
    
%     % Auditory input
%     if rand < 0.1
%         neuron_contacts(presynaptic_neuron, 3) = 1;
%         audio_prefs(presynaptic_neuron) = round(rand * 2000);
%     end
    
end

clear presynaptic_neuron
clear postsynaptic_neuron


