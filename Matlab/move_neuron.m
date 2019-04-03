

% Remove select neuron menu
delete(text_heading)
delete(button1)
delete(button2)
delete(button3)
delete(button4)
delete(button_cancel)

drawnow

% Design action: move neuron
fig_design.UserData = 4;

x = neuron_xys(presynaptic_neuron, 1);
y = neuron_xys(presynaptic_neuron, 2);

col = neuron_cols(presynaptic_neuron, :);

% Open selection props
% Heading 
text_heading = uicontrol('Style', 'text', 'String', 'Where do you want to move your neuron?', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

