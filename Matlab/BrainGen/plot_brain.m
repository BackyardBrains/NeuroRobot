

figure; bar(sort(a, 'descend')); title('A'); set(gcf, 'position', [1 540 400 300], 'color', 'w'); xlabel('Neuron');
figure; bar(sort(b, 'descend')); title('B'); set(gcf, 'position', [600 540 400 300], 'color', 'w'); xlabel('Neuron');
figure; bar(sort(c, 'descend')); title('C'); set(gcf, 'position', [600 30 400 300], 'color', 'w'); xlabel('Neuron');
figure; bar(sort(d, 'descend')); title('D'); set(gcf, 'position', [1 30 400 300], 'color', 'w'); xlabel('Neuron');

figure; imagesc(connectome); title('Connectome'); hc = colorbar; ylabel(hc, 'Synaptic Strength (w)'); ...
    set(gcf, 'position', [1200 540 400 300], 'color', 'w'); xlabel('Postsynaptic'); ylabel('Presynaptic');

figure; set(gcf, 'position', [1200 30 400 300], 'color', 'w'); brain_ax = axes('position', [0 0 1 1]);
im3 = flipud(255 - ((255 - imread('workspace.jpg')))); draw_synapses = 1; draw_synapse_strengths = 0; bfsize = 18;
gui_font_name = 'Comic Book'; gui_font_weight = 'normal'; draw_neuron_numbers = 0;
contact_xys = [-1.2, 2.05; 1.2, 2.1; -2.08, -0.38; 2.14, -0.38; ...
    -0.05, 2.45; -1.9, 1.45; -1.9, 0.95; -1.9, -1.78; ...
    -1.9, -2.28; 1.92, 1.49; 1.92, 0.95; 1.92, -1.82; 1.92, -2.29];
ncontacts = size(contact_xys, 1);
image('CData',im3,'XData',[-3 3],'YData',[-3 3]); set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
axis([-3 3 -3 3]); hold on; draw_brain; 

% export_fig(fig_print, horzcat('.\Data\', this_time, '-', brain_name, '-brain_print'), '-r150', '-jpg', '-nocrop')