
if ~exist('presynaptic_neuron', 'var')
    presynaptic_neuron = nneurons;
end

if button_n1.Value == 1 % Quiet
    edit_a.String = '0.02';
    edit_b.String = '0.1';
    edit_c.String = '-65';
    edit_d.String = '2';
    col = [1 0.9 0.8];
    button_n1.BackgroundColor = [0.6 0.95 0.6];
    button_n2.BackgroundColor = [0.8 0.8 0.8];
    button_n3.BackgroundColor = [0.8 0.8 0.8];
    button_n4.BackgroundColor = [0.8 0.8 0.8];
    button_n5.BackgroundColor = [0.8 0.8 0.8];
    button_n6.BackgroundColor = [0.8 0.8 0.8];
    button_n7.BackgroundColor = [0.8 0.8 0.8];
    da_rew_neurons(presynaptic_neuron, 1) = 0;
    bg_neurons(presynaptic_neuron, 1) = 0;
elseif button_n2.Value == 1 % Occasionally active
    edit_a.String = '0.02';
    edit_b.String = '0.16';
    edit_c.String = '-65';
    edit_d.String = '2';
    col = [1 0.9 0.8];
    button_n1.BackgroundColor = [0.8 0.8 0.8];
    button_n2.BackgroundColor = [0.6 0.95 0.6];
    button_n3.BackgroundColor = [0.8 0.8 0.8];
    button_n4.BackgroundColor = [0.8 0.8 0.8];
    button_n5.BackgroundColor = [0.8 0.8 0.8];
    button_n6.BackgroundColor = [0.8 0.8 0.8];
    button_n7.BackgroundColor = [0.8 0.8 0.8];
    da_rew_neurons(presynaptic_neuron, 1) = 0;
    bg_neurons(presynaptic_neuron, 1) = 0;
elseif button_n3.Value == 1 % Highly active
    edit_a.String = '0.02';
    edit_b.String = '0.2';
    edit_c.String = '-65';
    edit_d.String = '2';
    col = [1 0.9 0.8];
    button_n1.BackgroundColor = [0.8 0.8 0.8];
    button_n2.BackgroundColor = [0.8 0.8 0.8];
    button_n3.BackgroundColor = [0.6 0.95 0.6];
    button_n4.BackgroundColor = [0.8 0.8 0.8];
    button_n5.BackgroundColor = [0.8 0.8 0.8];
    button_n6.BackgroundColor = [0.8 0.8 0.8];
    button_n7.BackgroundColor = [0.8 0.8 0.8];
    da_rew_neurons(presynaptic_neuron, 1) = 0;
    bg_neurons(presynaptic_neuron, 1) = 0;
elseif button_n4.Value == 1 % Generates bursts
    edit_a.String = '0.02';
    edit_b.String = '0.16';
    edit_c.String = '-8';
    edit_d.String = '2';
    col = [1 0.9 0.8];
    button_n1.BackgroundColor = [0.8 0.8 0.8];
    button_n2.BackgroundColor = [0.8 0.8 0.8];
    button_n3.BackgroundColor = [0.8 0.8 0.8];
    button_n4.BackgroundColor = [0.6 0.95 0.6];
    button_n5.BackgroundColor = [0.8 0.8 0.8];
    button_n6.BackgroundColor = [0.8 0.8 0.8];
    button_n7.BackgroundColor = [0.8 0.8 0.8];
    da_rew_neurons(presynaptic_neuron, 1) = 0;
    bg_neurons(presynaptic_neuron, 1) = 0;
elseif button_n5.Value == 1 % Bursts when activated
    edit_a.String = '0.02';
    edit_b.String = '0.1';
    edit_c.String = '-13';
    edit_d.String = '2';
    col = [1 0.9 0.8];
    button_n1.BackgroundColor = [0.8 0.8 0.8];
    button_n2.BackgroundColor = [0.8 0.8 0.8];
    button_n3.BackgroundColor = [0.8 0.8 0.8];
    button_n4.BackgroundColor = [0.8 0.8 0.8];   
    button_n5.BackgroundColor = [0.6 0.95 0.6];
    button_n6.BackgroundColor = [0.8 0.8 0.8];
    button_n7.BackgroundColor = [0.8 0.8 0.8];
    da_rew_neurons(presynaptic_neuron, 1) = 0;
    bg_neurons(presynaptic_neuron, 1) = 0;
elseif button_n6.Value == 1 % Dopaminergic
    edit_a.String = '0.02';
    edit_b.String = '0.1';
    edit_c.String = '-65';
    edit_d.String = '2';
    col = [1 0.9 0.8];
    button_n1.BackgroundColor = [0.8 0.8 0.8];
    button_n2.BackgroundColor = [0.8 0.8 0.8];
    button_n3.BackgroundColor = [0.8 0.8 0.8];
    button_n4.BackgroundColor = [0.8 0.8 0.8];
    button_n5.BackgroundColor = [0.8 0.8 0.8];
    button_n6.BackgroundColor = [0.6 0.95 0.6]; 
    button_n7.BackgroundColor = [0.8 0.8 0.8];
    da_rew_neurons(presynaptic_neuron, 1) = 1;
    bg_neurons(presynaptic_neuron, 1) = 0;
elseif button_n7.Value == 1 % Striatal
    edit_a.String = '0.02';
    edit_b.String = '0.1';
    edit_c.String = '-65';
    edit_d.String = '2';
    col = network_colors(max([nnetworks 2]), :);
    button_n1.BackgroundColor = [0.8 0.8 0.8];
    button_n2.BackgroundColor = [0.8 0.8 0.8];
    button_n3.BackgroundColor = [0.8 0.8 0.8];
    button_n4.BackgroundColor = [0.8 0.8 0.8];
    button_n5.BackgroundColor = [0.8 0.8 0.8];
    button_n6.BackgroundColor = [0.8 0.8 0.8];
    button_n7.BackgroundColor = [0.6 0.95 0.6]; 
    da_rew_neurons(presynaptic_neuron, 1) = 0;  
    bg_neurons(presynaptic_neuron, 1) = 1;
    other_bgs = find(bg_neurons);
    connectome(other_bgs, presynaptic_neuron) = -1;
    connectome(presynaptic_neuron, other_bgs) = -1;
    if edit_id.Value == 1
        edit_id.Value = max([nnetworks 2]);
    end
end    

if fig_design.UserData == 1
    temp_plot(2).CData = col;
    neuron_cols(nneurons, 1:3) = col;
elseif fig_design.UserData == 3
    draw_neuron_core.CData(presynaptic_neuron, :) = col;
    neuron_cols(presynaptic_neuron, 1:3) = col;
end

