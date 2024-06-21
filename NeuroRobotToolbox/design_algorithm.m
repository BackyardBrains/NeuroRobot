% Add semi-random population

% Open selection menu
text_heading = uicontrol('Style', 'text', 'String', 'Generate Randomized Brain?', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

% How many neurons
text_w1 = uicontrol('Style', 'text', 'String', 'Neurons:', 'units', 'normalized', 'position', [0.02 0.86 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
edit_w1 = uicontrol('Style', 'edit', 'String', '5', 'units', 'normalized', 'position', [0.23 0.86 0.05 0.05], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);

% Probability of interconnection
text_w2 = uicontrol('Style', 'text', 'String', 'Connectivity (%):', 'units', 'normalized', 'position', [0.02 0.79 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
edit_w2 = uicontrol('Style', 'edit', 'String', '0.1', 'units', 'normalized', 'position', [0.23 0.79 0.05 0.05], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);

% b
text_w3 = uicontrol('Style', 'text', 'String', 'b:', 'units', 'normalized', 'position', [0.02 0.72 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
edit_w3 = uicontrol('Style', 'edit', 'String', '0.1 : 0.02 : 0.2', 'units', 'normalized', 'position', [0.23 0.72 0.05 0.05], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);

% c
text_w4 = uicontrol('Style', 'text', 'String', 'c:', 'units', 'normalized', 'position', [0.02 0.65 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
edit_w4 = uicontrol('Style', 'edit', 'String', '-100 : 5 : 0', 'units', 'normalized', 'position', [0.23 0.65 0.05 0.05], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);

% s
text_w5 = uicontrol('Style', 'text', 'String', 'Visual input (%):', 'units', 'normalized', 'position', [0.02 0.58 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
edit_w5 = uicontrol('Style', 'edit', 'String', '10', 'units', 'normalized', 'position', [0.23 0.58 0.05 0.05], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);

% m
text_w6 = uicontrol('Style', 'text', 'String', 'Motor output (%):', 'units', 'normalized', 'position', [0.02 0.51 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
edit_w6 = uicontrol('Style', 'edit', 'String', '10', 'units', 'normalized', 'position', [0.23 0.51 0.05 0.05], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);

% Network ID
text_id = uicontrol('Style', 'text', 'String', 'Network ID:', 'units', 'normalized', 'position', [0.02 0.44 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
edit_id = uicontrol('Style', 'edit', 'String', num2str(max([max(network_ids) 1])), 'units', 'normalized', 'position', [0.23 0.44 0.05 0.05], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);

