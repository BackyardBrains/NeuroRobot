

brain_directory = './Brains/*.mat';
available_brains = dir(brain_directory);
nbrains = size(available_brains, 1);
for nbrain = 1:nbrains
    brain_name = available_brains(nbrain).name(1:end-4);
    load(strcat('./Brains/', brain_name, '.mat'))
    
%     for nneuron = 1:brain.nneurons
%         for ncontact = 6:13
%             brain.neuron_contacts(nneuron, ncontact) = round(brain.neuron_contacts(nneuron, ncontact) / 2.5);
%         end
%     end
    
%     brain.neuron_scripts = zeros(brain.nneurons, 1);
    
%     neuron_cols = brain.neuron_cols;
%     network_ids = brain.network_ids;
%     network_colors = linspecer(length(unique(network_ids)));
%     nneurons = size(neuron_cols);
%     for nneuron = 1:nneurons
%         if network_ids(nneuron) == 1
%             neuron_cols(nneuron, :) = [1 0.9 0.8];
%         else
%             neuron_cols(nneuron, :) = network_colors(network_ids(nneuron), :);
%         end
%     end
% 
%     brain.neuron_cols = neuron_cols;

    brain = rmfield(brain, 'neuron_cols');
    
    save(strcat('./Brains/', brain_name, '.mat'), 'brain')    
    disp(num2str(nbrain / nbrains))
end

