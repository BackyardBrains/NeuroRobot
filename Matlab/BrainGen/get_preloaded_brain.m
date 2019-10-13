
load('bursting_brain')
nneurons = length(b);
start_brain = zeros(nneurons + 4, nneurons);
start_brain(1,:) = a;
start_brain(2,:) = b;
start_brain(3,:) = c;
start_brain(4,:) = d;
for nneuron = 1:nneurons
    start_brain(4+nneuron,:) = connectome(nneuron,:);
end
start_brain_vector = reshape(start_brain, [(nneurons + 4) * nneurons, 1]);