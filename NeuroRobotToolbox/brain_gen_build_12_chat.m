% Parameters
nneurons = 100;
p_connect = 0.1; % Probability of connection in small-world network
rewire_prob = 0.3; % Probability of rewiring in small-world network

% Generate Izhikevich neuron parameters
a = 0.02 * ones(nneurons,1);
b = 0.13 * ones(nneurons,1);
c = -65 + 5 * rand(nneurons,1) .^ 2;
d = 8 - 6 * rand(nneurons,1) .^ 2;

% Generate small-world network connectivity matrix
connectome = zeros(nneurons);
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
            end
        end
    end
end
connectome = connectome + connectome'; % Ensure symmetry

% Assign inputs and outputs to neurons
visual_input_prob = 0.1;
distance_input_prob = 0.1;
motor_output_prob = 0.1;
speaker_output_prob = 0.1;

vis_prefs = zeros(nneurons, 3, 2); % Visual preferences (color, side)
neuron_contacts = zeros(nneurons, 5); % Neuron contacts (inputs/outputs)

for presynaptic_neuron = 1:nneurons
    % Visual input
    if rand < visual_input_prob
        this_side = randsample(2, 1);
        this_color = randsample(3, 1);
        vis_prefs(presynaptic_neuron, this_color, this_side) = 1;
        neuron_contacts(presynaptic_neuron, this_side) = 1;
    end
    
    % Distance input
    if rand < distance_input_prob
        neuron_contacts(presynaptic_neuron, 5) = 1;
    end
    
    % Motor output
    if rand < motor_output_prob
        m_val = randsample([8 9 12 13], 1);
        neuron_contacts(presynaptic_neuron, m_val) = 250; 
    end
    
    % Speaker output
    if rand < speaker_output_prob
        neuron_tones(presynaptic_neuron, 1) = 500 + round(rand * 500);
        neuron_contacts(presynaptic_neuron, 4) = 1;
    end
end
