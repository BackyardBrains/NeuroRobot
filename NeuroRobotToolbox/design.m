

%% BRAIN DESIGN
sel_col_edge = [0.1 0.3 0.7];
sel_col_core = [0.6 0.8 1];

%% Create figure window
fig_design = figure(2);
clf
% set(fig_design, 'NumberTitle', 'off', 'Name', 'Brain Design')
set(fig_design, 'Name', 'SpikerBot - Design')
% set(fig_design, 'menubar', 'none', 'toolbar', 'none')
set(fig_design, 'position', fig_pos, 'color', fig_bg_col) 
fig_design.UserData = 0; % This indicates design mode

% Brain axes
brain_ax = axes('position', [0.31 0.02 0.67 0.96], 'xtick', [], 'ytick', []);
set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col, 'color', fig_bg_col)
brain_im = image('CData', im2, 'XData', [-3 3], 'YData', [-3 3]);
brain_im.ButtonDownFcn = 'location_in_brain_selected';
hold on
contact_size = 20;
draw_brain
b_y = 0.0472;

% Add neuron
neuron_or_network = 1;
button_add_neuron = uicontrol('Style', 'pushbutton', 'String', 'Add one neuron', 'units', 'normalized', 'position', [0.02 0.1664 + (0.0632 * 4) 0.26 b_y], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_add_neuron, 'Callback', 'if fig_design.UserData == 0 button_add_neuron.BackgroundColor = [0.6 0.95 0.6]; button_add_network.BackgroundColor = [0.8 0.8 0.8]; neuron_or_network = 1; multi_neuron_opt = 0; end;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
    


% Add Semi-random cluster
button_add_network = uicontrol('Style', 'pushbutton', 'String', 'Semi-random cluster', 'units', 'normalized', 'position', [0.02 0.1664 + (0.0632 * 3) 0.26 b_y], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_add_network, 'Callback', 'if fig_design.UserData == 0 button_add_network.BackgroundColor = [0.6 0.95 0.6]; button_add_neuron.BackgroundColor = [0.8 0.8 0.8]; neuron_or_network = 2; multi_neuron_opt = 1; end;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

% Brain 2 Circuit
button_add_network = uicontrol('Style', 'pushbutton', 'String', 'Brain 2 Circuit', 'units', 'normalized', 'position', [0.02 0.1664 + (0.0632 * 2) 0.26 b_y], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_add_network, 'Callback', 'if fig_design.UserData == 0 button_add_network.BackgroundColor = [0.6 0.95 0.6]; button_add_neuron.BackgroundColor = [0.8 0.8 0.8]; neuron_or_network = 2; multi_neuron_opt = 2; end;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

% Add Beautiful maths
button_add_network = uicontrol('Style', 'pushbutton', 'String', 'Beautiful maths', 'units', 'normalized', 'position', [0.02 0.1664 + 0.0632 0.26 b_y], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_add_network, 'Callback', 'if fig_design.UserData == 0 button_add_network.BackgroundColor = [0.6 0.95 0.6]; button_add_neuron.BackgroundColor = [0.8 0.8 0.8]; neuron_or_network = 2; multi_neuron_opt = 3; end;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

% Add Agents
button_add_network = uicontrol('Style', 'pushbutton', 'String', 'Agents', 'units', 'normalized', 'position', [0.02 0.1664 0.26 b_y], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_add_network, 'Callback', 'if fig_design.UserData == 0 button_add_network.BackgroundColor = [0.6 0.95 0.6]; button_add_neuron.BackgroundColor = [0.8 0.8 0.8]; neuron_or_network = 2; multi_neuron_opt = 4; end;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])


% Save brain
button_save = uicontrol('Style', 'pushbutton', 'String', 'Save brain', 'units', 'normalized', 'position', [0.02 0.1032 0.26 b_y]);
set(button_save, 'Callback', 'save_brain', 'FontSize', bfsize + 4, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

% Return to runtime
button_return_to_runtime = uicontrol('Style', 'pushbutton', 'String', 'Return to runtime', 'units', 'normalized', 'position', [0.02 0.04 0.26 b_y]);
set(button_return_to_runtime, 'Callback', 'if fig_design.UserData == 0; fig_design.UserData = 10; exit_design; end', 'FontSize', bfsize + 4, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

% Turn off motors
if exist('rak_only', 'var') && rak_only
    rak_cam.writeSerial('l:0;r:0;s:0;')
    rak_cam.writeSerial('d:120;d:220;d:320;d:420;d:520;d:620;')
elseif exist('use_esp32', 'var') && use_esp32
    esp32WebsocketClient.send('l:0;r:0;s:0;')
    esp32WebsocketClient.send('d:120;d:220;d:320;d:420;d:520;d:620;')
end

% Text heading
text_heading = uicontrol('Style', 'text', 'String', 'Click in brain to add neurons', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'fontname', gui_font_name);


