

%% BRAIN DESIGN
sel_col_edge = [0.1 0.3 0.7];
sel_col_core = [0.6 0.8 1];

%% Create figure window
fig_design = figure(2);
clf
set(fig_design, 'NumberTitle', 'off', 'Name', 'SpikerBot - Design')
set(fig_design, 'menubar', 'none', 'toolbar', 'none')
set(fig_design, 'position', fig_pos, 'color', fig_bg_col) 
fig_design.UserData = 0; % This indicates design mode
% set(fig_design, 'CloseRequestFcn', 'stop(runtime_pulse); closereq')

% Brain axes
brain_ax = axes('position', [0.31 0.02 0.67 0.96], 'xtick', [], 'ytick', []);
set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col, 'color', fig_bg_col)
brain_im = image('CData', im2, 'XData', [-3 3], 'YData', [-3 3]);
brain_im.ButtonDownFcn = 'location_in_brain_selected';
hold on
contact_size = 20;
draw_brain


%% Turn off motors
if exist('rak_only', 'var') && rak_only
    rak_cam.writeSerial('l:0;r:0;s:0;')
    rak_cam.writeSerial('d:120;d:220;d:320;d:420;d:520;d:620;')
elseif exist('use_esp32', 'var') && use_esp32
    esp32WebsocketClient.send('l:0;r:0;s:0;')
    just_purple
end


%% Buttons
neuron_or_network = 1;
multi_neuron_opt = 0;

design_buttons

% % Text heading
% text_heading = uicontrol('Style', 'text', 'String', 'Click in brain to add neurons', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'fontname', gui_font_name);


