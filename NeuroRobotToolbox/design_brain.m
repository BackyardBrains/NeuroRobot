
% Add brain as circuit

% Open selection menu
text_heading = uicontrol('Style', 'text', 'String', 'What do you want to integrate?', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

text_w1 = uicontrol('Style', 'text', 'String', 'Available brains', 'units', 'normalized', 'position', [0.02 0.86 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

popup_select_brain = uicontrol('Style', 'popup', 'String', brain_string(1:end), 'callback', '', 'units', 'normalized', ...
    'position', [0.02 0.81 0.26 0.05], 'fontsize', bfsize + 4, 'fontweight', gui_font_weight, 'FontName', gui_font_name);


