

%% Prepare figure
fig_design = figure(2);
clf
set(fig_design, 'NumberTitle', 'off', 'Name', 'SpikerBot Runtime')
set(fig_design, 'menubar', 'none', 'toolbar', 'none')
set(fig_design, 'position', fig_pos, 'color', fig_bg_col) 
fig_design.UserData = 10; % This indicates runtime mode
% set(fig_design, 'CloseRequestFcn', 'stop(runtime_pulse); closereq')

% Prepare axes
brain_ax_pos = [0.27 0.25 0.46 0.73];
brain_ax = axes('position', brain_ax_pos);
image('CData',im,'XData',[-3 3],'YData',[-3 3])
set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col)
axis([-3 3 -3 3])
hold on 

left_eye_ax = axes('position', [0.02 0.58 0.23 0.36], 'xtick', [], 'ytick', []);
right_eye_ax = axes('position', [0.75 0.58 0.23 0.36], 'xtick', [], 'ytick', []);
activity_ax = axes('position', [0.04 0.09 0.94 0.14], 'linewidth', 2);

% Microphone data plot
audio_ax_pos = [0.04 0.3 0.21 0.2];
audio_ax = axes('position', audio_ax_pos);
if audio_th
    draw_audio = imagesc(sound_spectrum, [0 audio_th]);
else
    draw_audio = imagesc(sound_spectrum, [0 1]);
end
set(audio_ax, 'ytick', round(linspace(1, audx, 5)), 'yticklabel', round(linspace(0, 4, 5)), ...
    'xtick', [], 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', ...
    gui_font_weight, 'linewidth', 2, 'ydir', 'normal')
cmap = flipud(gray);
colormap(audio_ax, cmap)
hold on
cplot_front = plot([0 0], [0 audx], 'color', 'r', 'linewidth', 2);
title('Microphone', 'FontSize', bfsize + 6, 'fontname', gui_font_name, 'fontweight', gui_font_weight)
ylabel('kHz', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight)   

if bg_brain
    
    drive_bar_pos = [0.75 0.3 0.23 0.2];
    drive_bar_ax = axes('position', drive_bar_pos, 'linewidth', 2);
    if ~isempty(network_drive)
        drive_bar = bar(network_drive(2:end,1), 'linewidth', 2);
        if bg_colors
            drive_bar.FaceColor = 'flat';
            for nnetwork = 2:nnetworks
                drive_bar.CData(nnetwork - 1, :) = network_colors(nnetwork, :);
            end
        end
    else
        drive_bar = bar(0, 'linewidth', 2);
    end
    drive_bar_ax.Color = fig_bg_col;
    set(drive_bar_ax, 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'linewidth', 2)
    title('Basal Ganglia', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight)
    xlabel('Network', 'FontSize', bfsize + 4, 'fontname', gui_font_name);
    ylim([0 255])
    set(drive_bar_ax, 'xtick', 1:nnetworks-1, 'xticklabels', letters(2:nnetworks), 'ytick', [], 'ycolor', fig_bg_col)
    box off
elseif manual_controls
    left_pos = [0.75 0.37 0.07 0.05];
    right_pos = [0.91 0.37 0.07 0.05];
    forward_pos =[0.81 0.44 0.11 0.05];
    backward_pos = [0.81 0.3 0.11 0.05];
    hold_pos = [0.83 0.37 0.07 0.05];
    button_left = uicontrol('Style', 'pushbutton', 'String', 'Left', 'units', 'normalized', 'position', left_pos);
    set(button_left, 'Callback', 'manual_control = 1;', 'FontSize', bfsize+ 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.9 0.9 0.9])
    button_right = uicontrol('Style', 'pushbutton', 'String', 'Right', 'units', 'normalized', 'position', right_pos);
    set(button_right, 'Callback', 'manual_control = 2;', 'FontSize', bfsize+ 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.9 0.9 0.9])
    button_forward = uicontrol('Style', 'pushbutton', 'String', 'Forward', 'units', 'normalized', 'position', forward_pos);
    set(button_forward, 'Callback', 'manual_control = 3;', 'FontSize', bfsize+ 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.9 0.9 0.9])
    button_backward = uicontrol('Style', 'pushbutton', 'String', 'Backward', 'units', 'normalized', 'position', backward_pos);
    set(button_backward, 'Callback', 'manual_control = 4;', 'FontSize', bfsize+ 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.9 0.9 0.9])
    button_hold = uicontrol('Style', 'pushbutton', 'String', 'Hold', 'units', 'normalized', 'position', hold_pos);
    set(button_hold, 'Callback', 'manual_control = 5;', 'FontSize', bfsize+ 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.9 0.9 0.9])
    manual_control_title = uicontrol('style', 'text', 'string', 'Manual control', 'units', 'normalized', 'position', [0.75 0.5 0.23 0.05], 'FontSize', bfsize+ 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'horizontalalignment', 'center', 'backgroundcolor', fig_bg_col);
end

% Activity axes
axes(activity_ax)
hold on
if nneurons
    [y, x] = find(spikes_loop);
    if isempty(x)
        x = ms_per_step * nsteps_per_loop + 1; % edited for appearence
        y = 1;
    end
%     vplot = plot(x, y, 'linestyle', 'none', 'marker', '.', 'markersize', max([min([15, 45 - nneurons]), 5])   , 'color', 'k');
    vplot = plot(x, y, 'linestyle', 'none', 'marker', '.', 'markersize', 5 , 'color', 'k');
    this_val = nneurons;
else
    vplot = plot(1, ms_per_step * nsteps_per_loop, 'linestyle', 'none', 'marker', '.', 'markersize', 1, 'color', 'k');
    this_val = 1;
end
vplot_front = plot([0 0], [0 this_val + 1], 'color', 'r', 'linewidth', 2);
xlim([0 ms_per_step * nsteps_per_loop + 0])
ylim([0 this_val + 1])
set(gca, 'xtick', [], 'ytick', 1:round(nneurons/5):nneurons, 'yticklabels', 1:round(nneurons/5):nneurons, 'fontsize', bfsize + 4, 'ydir', 'reverse', 'xcolor', 'k', 'ycolor', 'k', 'fontname', gui_font_name, 'fontweight', gui_font_weight)
ylabel('Neuron', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight)
box on

% Initialize camera streams
axes(left_eye_ax)
show_left_eye = image(zeros(left_yx(1), left_yx(2), 3, 'uint8'));
title('Left eye', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight)
set(left_eye_ax, 'xtick', [], 'ytick', [], 'linewidth', 2)
box on

axes(right_eye_ax)
show_right_eye = image(zeros(right_yx(1), right_yx(2), 3, 'uint8'));
title('Right eye', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight)
set(right_eye_ax, 'xtick', [], 'ytick', [], 'linewidth', 2)
box on

%% Buttons
button1_pos = [0.03 0.02 0.17 0.05];
button2_pos = [0.22 0.02 0.17 0.05];
button3_pos = [0.41 0.02 0.17 0.05];
button4_pos = [0.6 0.02 0.17 0.05];
button5_pos = [0.79 0.02 0.17 0.05];

button_design = uicontrol('Style', 'pushbutton', 'String', 'Design', 'units', 'normalized', 'position', button1_pos);
set(button_design,'Callback', 'run_button = 1;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_save = uicontrol('Style', 'pushbutton', 'String', 'Save', 'units', 'normalized', 'position', button2_pos);
set(button_save,'Callback', 'run_button = 2;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_pause = uicontrol('Style', 'pushbutton', 'String', 'Sleep', 'units', 'normalized', 'position', button3_pos);
set(button_pause,'Callback', 'sleep_networks;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_reward = uicontrol('Style', 'pushbutton', 'String', 'Dopamine', 'units', 'normalized', 'position', button4_pos);
set(button_reward,'Callback', 'run_button = 5;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

button_stop = uicontrol('Style', 'pushbutton', 'String', 'Menu', 'units', 'normalized', 'position', button5_pos);
set(button_stop,'Callback', 'run_button = 4;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

