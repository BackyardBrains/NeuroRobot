

brain_directory = './Brains/*.mat';
available_brains = dir(brain_directory);
nbrains = size(available_brains, 1);
for nbrain = 1:nbrains
    brain_name = available_brains(nbrain).name(1:end-4);
    load(strcat('./Brains/', brain_name, '.mat'))
    
    for ncontact = 6:13
        if brain.neuron_contacts(ncontact)
            brain.neuron_contacts(ncontact) = brain.neuron_contacts(ncontact) / 2.5;
        end
    end
    
    save(strcat('./Brains/', brain_name, '.mat'), 'brain')    
    disp(num2str(nbrain / nbrains))
end

