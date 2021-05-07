

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
    
    neuron_cols = brain.neuron_cols;
    nneurons = length(neuron_cols, 1);
    for nneuron = 1:nneurons
        neuron_cols(nneuron, :) = lineStyles(nneuron, :);
    end

    save(strcat('./Brains/', brain_name, '.mat'), 'brain')    
    disp(num2str(nbrain / nbrains))
end

