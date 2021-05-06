for nneuron = 1:nneurons
    if sum(neuron_contacts(nneuron, 1:3))
        for nneuron2 = 1:nneurons
%             if neuron_contacts(nneuron2, 4)
            if bg_neurons(nneuron2, 1)
                connectome(nneuron, nneuron2) = 5;
                da_connectome(nneuron, nneuron2, 1) = 2; % is the synapse plastic (1 = yes, 2 = yes with reward)?
                da_connectome(nneuron, nneuron2, 2) = 5; % pre-reinforcement synapse weight
                da_connectome(nneuron, nneuron2, 3) = 0; % learning intensity variable        
            end
            if network_ids(nneuron2) == network_ids(nneuron)
                connectome(nneuron, nneuron2) = 20;
                da_connectome(nneuron, nneuron2, 1) = 0; % is the synapse plastic (1 = yes, 2 = yes with reward)?
                da_connectome(nneuron, nneuron2, 2) = 0; % pre-reinforcement synapse weight
                da_connectome(nneuron, nneuron2, 3) = 0; % learning intensity variable                        
            end
        end
    end
end

counter = 0;
for nneuron = 1:nneurons
    if neuron_contacts(nneuron, 4)
        b(nneuron) = 0.1;
        counter = counter + 1;
        network_ids(nneuron) = counter;
    end
end

draw_brain