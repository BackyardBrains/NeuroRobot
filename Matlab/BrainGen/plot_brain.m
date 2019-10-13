

figure(1)
clf
set(gcf, 'color', 'w', 'position', [10 50 1480 720])

subplot(2,3,1)
bar(sort(a, 'descend')); title('Izhikevich A'); xlabel('Neuron');

subplot(2,3,2)
bar(sort(b, 'descend')); title('Izhikevich B'); xlabel('Neuron');

subplot(2,3,4)
bar(sort(c, 'descend')); title('Izhikevich C'); xlabel('Neuron');

subplot(2,3,5)
bar(sort(d, 'descend')); title('Izhikevich D'); xlabel('Neuron');

subplot(2,3,3)
imagesc(connectome); title('Connectome'); hc = colorbar; ylabel(hc, 'Synaptic Strength (w)'); 
xlabel('Postsynaptic'); ylabel('Presynaptic');

brain_ax = subplot(2,3,6);
im3 = flipud(255 - ((255 - imread('workspace.jpg')))); 
draw_synapses = 0; draw_synapse_strengths = 0; bfsize = 18;
gui_font_name = 'Comic Book'; gui_font_weight = 'normal'; draw_neuron_numbers = 0;
contact_xys = [-1.2, 2.05; 1.2, 2.1; -2.08, -0.38; 2.14, -0.38; ...
    -0.05, 2.45; -1.9, 1.45; -1.9, 0.95; -1.9, -1.78; ...
    -1.9, -2.28; 1.92, 1.49; 1.92, 0.95; 1.92, -1.82; 1.92, -2.29];
ncontacts = size(contact_xys, 1);
image('CData',im3,'XData',[-3 3],'YData',[-3 3]); set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
axis([-3 3 -3 3]); hold on;
draw_brain

% export_fig(fig_print, horzcat('.\Data\', this_time, '-', brain_name, '-brain_print'), '-r150', '-jpg', '-nocrop')