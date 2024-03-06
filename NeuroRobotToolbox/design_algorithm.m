



% Add netalgos

available_netalgos = dir(strcat(netalgo_dir_name));

clear netalgo_string
nnetalgos = size(available_netalgos, 1);
for nbrain = 1:nnetalgos
    netalgo_string{nbrain} = available_netalgos(nbrain).name;
end

% Open selection menu
text_heading = uicontrol('Style', 'text', 'String', 'Which network algorithm do you want to integrate?', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

text_w1 = uicontrol('Style', 'text', 'String', 'Available network algorithms', 'units', 'normalized', 'position', [0.02 0.86 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

popup_select_netalgo = uicontrol('Style', 'popup', 'String', netalgo_string, 'callback', '', 'units', 'normalized', ...
    'position', [0.02 0.81 0.26 0.05], 'fontsize', bfsize + 4, 'fontweight', gui_font_weight, 'FontName', gui_font_name);

