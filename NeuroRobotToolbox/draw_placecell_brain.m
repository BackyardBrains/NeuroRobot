

% This is part of the hippocampus/SLAM simulation. Not currently active.


%%set visual input to line up with mem Images

%%How to draw this on the runtime setup?

%% Prepare figure
fig_design = figure(2);
clf
set(fig_design, 'NumberTitle', 'off', 'Name', horzcat('Neurorobot Runtime (restarts = ', num2str(restarts), ')'))
set(fig_design, 'menubar', 'none', 'toolbar', 'none')
set(fig_design, 'position', fig_pos, 'color', fig_bg_col) 
fig_design.UserData = 10; % This indicates runtime mode

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

% Manual controls
if bg_brain
       
%     drive_bar_pos = [0.75 0.3 0.23 0.2];
%     drive_bar_ax = axes('position', drive_bar_pos, 'linewidth', 2);
%     if ~isempty(network_drive)
%         drive_bar = bar(network_drive(2:end,1), 'linewidth', 2);
%     else
%         drive_bar = bar(0, 'linewidth', 2);
%     end
%     drive_bar_ax.Color = fig_bg_col;
%     set(drive_bar_ax, 'FontSize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'linewidth', 2)
%     title('Drive / Motivation', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight)
%     xlabel('Network / Channel', 'FontSize', bfsize, 'fontname', gui_font_name);
%     ylim([0 255])
%     set(drive_bar_ax, 'xtick', 1:nnetworks-1, 'xticklabels', 2:nnetworks, 'ytick', [], 'ycolor', fig_bg_col)
%     box off
elseif manual_controls
    left_pos = [0.75 0.37 0.07 0.05];
    right_pos = [0.91 0.37 0.07 0.05];
    forward_pos =[0.81 0.44 0.11 0.05];
    backward_pos = [0.81 0.3 0.11 0.05];
    hold_pos = [0.83 0.37 0.07 0.05];
    button_left = uicontrol('Style', 'pushbutton', 'String', 'Left', 'units', 'normalized', 'position', left_pos);
    set(button_left, 'Callback', 'manual_control = 1;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.9 0.9 0.9])
    button_right = uicontrol('Style', 'pushbutton', 'String', 'Right', 'units', 'normalized', 'position', right_pos);
    set(button_right, 'Callback', 'manual_control = 2;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.9 0.9 0.9])
    button_forward = uicontrol('Style', 'pushbutton', 'String', 'Forward', 'units', 'normalized', 'position', forward_pos);
    set(button_forward, 'Callback', 'manual_control = 3;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.9 0.9 0.9])
    button_backward = uicontrol('Style', 'pushbutton', 'String', 'Backward', 'units', 'normalized', 'position', backward_pos);
    set(button_backward, 'Callback', 'manual_control = 4;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.9 0.9 0.9])
    button_hold = uicontrol('Style', 'pushbutton', 'String', 'Hold', 'units', 'normalized', 'position', hold_pos);
    set(button_hold, 'Callback', 'manual_control = 5;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.9 0.9 0.9])
    manual_control_title = uicontrol('style', 'text', 'string', 'Manual control', 'units', 'normalized', 'position', [0.75 0.5 0.23 0.05], 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'horizontalalignment', 'center', 'backgroundcolor', fig_bg_col);
end


axes(activity_ax)
hold on
if nneurons
    [y, x] = find(spikes_loop);
    if isempty(x)
        x = ms_per_step * nsteps_per_loop + 1; % edited for appearence
        y = 1;
    end
    vplot = plot(x, y, 'linestyle', 'none', 'marker', '.', 'markersize', max([min([15, 45 - nneurons]), 5])   , 'color', 'k');
    this_val = nneurons;
else
    vplot = plot(1, ms_per_step * nsteps_per_loop, 'linestyle', 'none', 'marker', '.', 'markersize', 1, 'color', 'k');
    this_val = 1;
end

vplot_front = plot([0 0], [0 this_val + 1], 'color', 'r', 'linewidth', 2);
xlim([0 ms_per_step * nsteps_per_loop + 0])
ylim([0 this_val + 1])
set(gca, 'xtick', [], 'ytick', 1:round(nneurons/5):nneurons, 'yticklabels', 1:round(nneurons/5):nneurons, 'fontsize', bfsize - 6, 'ydir', 'reverse', 'xcolor', 'k', 'ycolor', 'k', 'fontname', gui_font_name, 'fontweight', gui_font_weight)
ylabel('Neuron', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight)
box on

% Initialize camera streams
axes(left_eye_ax)
show_left_eye = image(zeros(left_yx(1), left_yx(2), 3, 'uint8'));
title('Left eye', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight)
set(left_eye_ax, 'xtick', [], 'ytick', [], 'linewidth', 2)
box on

axes(right_eye_ax)
show_right_eye = image(zeros(right_yx(1), right_yx(2), 3, 'uint8'));
title('Right eye', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight)
set(right_eye_ax, 'xtick', [], 'ytick', [], 'linewidth', 2)
box on

set_1

%% Settings
nneurons = dim1*dim2;


%% Prepare
a = 0.02 * ones(nneurons,1);
b = 0.15 * ones(nneurons,1);
c = -65 + 5 * rand(nneurons,1) .^ 2;
d = 8 - 6 * rand(nneurons,1) .^ 2;
connectome = zeros(nneurons);
v = -65 + 5 * rand(nneurons,1) .^ 2;
u = b .* v;
brain = struct;
neuron_contacts = zeros(nneurons, 13);
dist_prefs = zeros(nneurons, 1);
audio_prefs = zeros(nneurons, 1);
network_ids = ones(nneurons, 1);
da_rew_neurons = zeros(nneurons, 1);
neuron_tones = zeros(nneurons, 1);
bg_neurons = zeros(nneurons, 1);
da_connectome = zeros(nneurons, nneurons, 3);
neuron_cols(:, 1:3) = repmat([1 0.9 0.8], [nneurons, 1]);
steps_since_last_spike(1:nneurons) = nan;
network = struct;
nnetworks = length(unique(network_ids));
network_drive = zeros(nnetworks, 3);
spikes_loop = zeros(nneurons, ms_per_step * nsteps_per_loop);
neuron_xys = zeros(nneurons, 2);


%% Anatomy
xrange = linspace(-1.5, 1.5, sqrt(nneurons));
yrange = linspace(1.3, -1.7, sqrt(nneurons));
[xg,yg] = meshgrid(xrange,yrange);
counter = 0;
for nx = 1:sqrt(nneurons)
    for ny = 1:sqrt(nneurons)
        counter = counter + 1;
        neuron_xys(counter, :) = [xg(nx, ny), yg(nx, ny)];
    end
end

draw_brain



