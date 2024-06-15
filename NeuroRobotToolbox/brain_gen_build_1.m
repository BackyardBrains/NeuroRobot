

nneurons = 100;
p_connect = 0.1; % Probability of connection in small-world network
rewire_prob = 0.3; % Probability of rewiring in small-world network

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
neuron_xys = neuron_xys * 0.9;


%%
for i = 1:nneurons
    for j = i+1:nneurons
        if rand < p_connect
            connectome(i,j) = 10 * rand; % Random weight for connection
            % Small-world rewiring
            if rand < rewire_prob
                % Rewire to a random neuron
                j_new = randsample(setdiff(1:nneurons, [i j]), 1);
                connectome(i,j) = 0; % Remove original connection
                connectome(i,j_new) = 10 * rand; % Create new connection
                da_connectome(i, j_new, 2) = connectome(i,j_new);   
            end
        end
    end
end
connectome = connectome + connectome'; % Ensure symmetry

% for presynaptic_neuron = 1:nneurons
% 
%     for postsynaptic_neuron = 1:nneurons
% 
%         this_weight = 0;
%         xe = abs(neuron_xys(presynaptic_neuron, 1) - neuron_xys(postsynaptic_neuron, 1));
%         ye = abs(neuron_xys(presynaptic_neuron, 2) - neuron_xys(postsynaptic_neuron, 2));
%         ce = sqrt(xe^2 + ye^2);
% 
%         if ce > 0.2 && ce <= 0.7 && rand < 0.5
%             this_weight = 15 * rand;
%         end
%         connectome(presynaptic_neuron, postsynaptic_neuron) = this_weight;
% 
%         da_connectome(presynaptic_neuron, postsynaptic_neuron, 1) = 0;
%         da_connectome(presynaptic_neuron, postsynaptic_neuron, 2) = this_weight;   
%         da_connectome(presynaptic_neuron, postsynaptic_neuron, 3) = 0;      
% 
%     end
% 
%     if rand < 0.1 % Visual input
%         this_side = randsample(2,1);
%         this_color = randsample(3,1);
%         vis_prefs(presynaptic_neuron, this_color, this_side) = 1;
%         neuron_contacts(presynaptic_neuron, this_side) = 1;
%     end
% 
%     if rand < 0.1 % Distance input
%         neuron_contacts(presynaptic_neuron, 5) = 1;
%     end
% 
%     if rand < 0.1 % Motor output
%         m_val = randsample([8 9 12 13],1);
%         neuron_contacts(presynaptic_neuron, m_val) = 100;  
%     end
% 
%     if rand < 0.1 % Speaker output
%         neuron_tones(presynaptic_neuron, 1) = 500 + round(rand * 500);
%         neuron_contacts(presynaptic_neuron, 4) = 1;
%     end
% 
% end

clear presynaptic_neuron
clear postsynaptic_neuron

draw_brain

