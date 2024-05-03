
% TWO NEURON SIMULATOR 
% By Christopher Harris, Backyard Brains
% christopher@backyardbrains.com
%
% Brain simulation and neurorobotics will revolutionize neuroscience
% education provided there are user-friendly software tools to help
% non-experts develop an intuitive practical understanding of computational
% neuroscience concepts. This Two Neuron Simulator runs a pair of connected
% artificial (Izhikevich) neurons in a continuous loop. A nice java trick
% (findjobj by Yair M. Altman) allows the parameters of each neuron to be
% changed smoothly in real-time with sliders. This immediate feedback helps
% create an intuitive sense of how the neurons work.
%
% For more information about the Izhikevich neuron model, see
% https://www.izhikevich.org/publications/spikes.htm
%
% For more information about educational neurorobotics at Backyard Brains,
% see http://blog.backyardbrains.com/2018/06/brain-design-with-neurorobots
%
% The Two Neuron Simulator is written and maintained by Christopher Harris,
% neurorobotics lead at Backyard Brains. (christopher@backyardbrains.com).
% License to use and modify this code is granted freely to all interested
% as long as the original author is referenced and attributed as such.
%
% For the best experience, install the included Comic Book font :)
%
% In progress: easy options to use pre-configured settings that simulate
% different cortical neurons; educational resources. Last update:
% 2018-08-22.



%% Close and clear
% delete(timerfind)
% close all
% clear


%% Settings
ms_per_step = 30;
steps_per_loop = 200;


%% Constants
clear a b c d
special_font = 'Comic Book';
nneurons = 2;
neuron_xys = [-1 0; 1 0];
neuron_cols = [1 0.9 0.8; 1 0.9 0.8];       
firing = [];
v_traces = zeros(nneurons, ms_per_step * steps_per_loop);
a_init = 0.02;
b_init = 0.18;
c_init = -65;
d_init = 2;
noise_init = 5;
w_init = 2;
a(1:nneurons, 1) = a_init;
b(1:nneurons, 1) = b_init;
c(1:nneurons, 1) = c_init;
d(1:nneurons, 1) = d_init;
i_rand(1:nneurons, 1) = noise_init;
v = c + 5 * randn(nneurons, 1);
u = b .* v;
connectome = [0 w_init; w_init 0];
pause_flag = 0;
intended_timer_period = ms_per_step/1000;


%% Prepare figure
fig_2ns = figure(8);
clf
fig_bg_col = [0.94 0.94 0.94];
% fig_bg_col = [1 1 1];
fig_2ns.UserData = [a_init b_init c_init d_init noise_init w_init a_init b_init c_init d_init noise_init w_init];
screen_dims = get(0, 'screensize');
screen_size_constant = round(screen_dims(3)/96);
set(fig_2ns, 'NumberTitle', 'off', 'Name', 'Two Neuron Simulator')
set(fig_2ns, 'menubar', 'none', 'toolbar', 'none')
set(fig_2ns, 'position', [screen_dims(1) screen_dims(2) + 40 screen_dims(3) screen_dims(4) - 63], 'color', fig_bg_col) 

% Positions
title_pos = [0.02 0.92 0.96 0.06];

slider_length = 0.24;
slider_height = 0.03;
a1_pos = [0.04 0.82 slider_length slider_height];
b1_pos = [0.04 0.74 slider_length slider_height];
c1_pos = [0.04 0.66 slider_length slider_height];
d1_pos = [0.04 0.58 slider_length slider_height];
i1_pos = [0.04 0.5 slider_length slider_height];
w1_pos = [0.04 0.42 slider_length slider_height];

a2_pos = [0.72 0.82 slider_length slider_height];
b2_pos = [0.72 0.74 slider_length slider_height];
c2_pos = [0.72 0.66 slider_length slider_height];
d2_pos = [0.72 0.58 slider_length slider_height];
i2_pos = [0.72 0.5 slider_length slider_height];
w2_pos = [0.72 0.42 slider_length slider_height];

brain_pos = [0.32 0.4 0.36 0.5];
activity_pos = [0.04 0.08 0.92 0.3];
pause_button_pos = [0.33 0.02 0.16 0.04];
stop_button_pos = [0.51 0.02 0.16 0.04];

% Title
text_title = uicontrol('Style', 'text', 'String', 'Two Neuron Simulator', 'units', 'normalized', 'position', title_pos, 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant + 10, 'horizontalalignment', 'center');

% Neurons and synapses
brain_ax = axes('position', brain_pos);
set(brain_ax, 'xtick', [], 'ytick', [], 'color', fig_bg_col, 'xcolor', fig_bg_col, 'ycolor', fig_bg_col)
hold on
box off
plot([-1 0.31], [0.2 0.2], 'linewidth', 5, 'color', [0 0 0]);
plot(0.31, 0.2, 'marker', 'square', 'markersize', 17, 'linewidth', 10, 'markerfacecolor', fig_bg_col, 'markeredgecolor', 'k');
plot([1 -0.31], [-0.2 -0.2], 'linewidth', 5, 'color', [0 0 0]);
plot(-0.31, -0.2, 'marker', 'square', 'markersize', 17, 'linewidth', 10, 'markerfacecolor', fig_bg_col, 'markeredgecolor', 'k');
edge_size = 1020 * screen_size_constant;
core_size = 840 * screen_size_constant;             
draw_neuron_edge = scatter(neuron_xys(:,1), neuron_xys(:,2), edge_size, zeros(size(neuron_xys,1), 3), 'filled');
draw_neuron_core = scatter(neuron_xys(:,1), neuron_xys(:,2), core_size, neuron_cols, 'filled');
for nneuron = 1:nneurons
    text(neuron_xys(nneuron,1), neuron_xys(nneuron,2), num2str(nneuron), 'fontsize', screen_size_constant + 24, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'fontname', special_font);
end
axis([-2 2 -2 2])

% Activity
activity_ax = axes('position', activity_pos, 'linewidth', 2);
set(activity_ax, 'xtick', [], 'ytick', [])
box on
hold on
vplot1 = plot(v_traces(1, :) - 2000, 'color', 'k');
vplot2 = plot(v_traces(2, :) - 2000, 'color', 'k');
vplot_front = plot([0 0], [-100 180], 'color', 'r');
ylim([-100 180])
xlim([0 ms_per_step * steps_per_loop])
set(gca, 'xtick', [], 'ytick', [])
box on
text(-70, -65, '2', 'FontSize', screen_size_constant, 'fontname', special_font, 'verticalalignment', 'middle', 'horizontalalignment', 'center')
text(-70, 65, '1', 'FontSize', screen_size_constant, 'fontname', special_font, 'verticalalignment', 'middle', 'horizontalalignment', 'center')

% Parameter sliders
a_str = 'a: speed of recovery';
b_str = 'b: sensitivity to fluctuations';
c_str = 'c: after-spike reset value';
d_str = 'd: after-spike inhibition';
i_str = 'i: input noise';
w_str = 'w: synaptic strength';

% A1
a1_val = uicontrol('Style', 'text', 'String', num2str(a_init), 'units', 'normalized', 'position', [a1_pos(1) + a1_pos(3) a1_pos(2) 0.04 a1_pos(4)], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 5, 'horizontalalignment', 'center');
a1_title = uicontrol('Style', 'text', 'String', a_str, 'units', 'normalized', 'position', [a1_pos(1) a1_pos(2) + 0.03 a1_pos(3) 0.03], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 2, 'horizontalalignment', 'center');
a1_slider = uicontrol('style', 'slider', 'units', 'normalized', 'position', a1_pos);
a1_slider.Value = a_init / 0.15;
a1_jslider = findjobj(a1_slider);
a1_jslider.AdjustmentValueChangedCallback = {@a1, fig_2ns, a1_val};

% B1
b1_val = uicontrol('Style', 'text', 'String', num2str(b_init), 'units', 'normalized', 'position', [b1_pos(1) + b1_pos(3) b1_pos(2) 0.04 b1_pos(4)], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 5, 'horizontalalignment', 'center');
b1_title = uicontrol('Style', 'text', 'String', b_str, 'units', 'normalized', 'position', [b1_pos(1) b1_pos(2) + 0.03 b1_pos(3) 0.03], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 2, 'horizontalalignment', 'center');
b1_slider = uicontrol('style', 'slider', 'units', 'normalized', 'position', b1_pos);
b1_slider.Value = b_init / 0.5;
b1_jslider = findjobj(b1_slider);
b1_jslider.AdjustmentValueChangedCallback = {@b1, fig_2ns, b1_val};

% C1
c1_val = uicontrol('Style', 'text', 'String', num2str(c_init), 'units', 'normalized', 'position', [c1_pos(1) + c1_pos(3) c1_pos(2) 0.04 c1_pos(4)], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 5, 'horizontalalignment', 'center');
c1_title = uicontrol('Style', 'text', 'String', c_str, 'units', 'normalized', 'position', [c1_pos(1) c1_pos(2) + 0.03 c1_pos(3) 0.03], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 2, 'horizontalalignment', 'center');
c1_slider = uicontrol('style', 'slider', 'units', 'normalized', 'position', c1_pos);
c1_slider.Value = 0.35;
c1_jslider = findjobj(c1_slider);
c1_jslider.AdjustmentValueChangedCallback = {@c1, fig_2ns, c1_val};

% D1
d1_val = uicontrol('Style', 'text', 'String', num2str(d_init), 'units', 'normalized', 'position', [d1_pos(1) + d1_pos(3) d1_pos(2) 0.04 d1_pos(4)], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 5, 'horizontalalignment', 'center');
d1_title = uicontrol('Style', 'text', 'String', d_str, 'units', 'normalized', 'position', [d1_pos(1) d1_pos(2) + 0.03 d1_pos(3) 0.03], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 2, 'horizontalalignment', 'center');
d1_slider = uicontrol('style', 'slider', 'units', 'normalized', 'position', d1_pos);
d1_slider.Value = 0.2;
d1_jslider = findjobj(d1_slider);
d1_jslider.AdjustmentValueChangedCallback = {@d1, fig_2ns, d1_val};

% I1
i1_val = uicontrol('Style', 'text', 'String', num2str(noise_init), 'units', 'normalized', 'position', [i1_pos(1) + i1_pos(3) i1_pos(2) 0.04 i1_pos(4)], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 5, 'horizontalalignment', 'center');
i1_title = uicontrol('Style', 'text', 'String', i_str, 'units', 'normalized', 'position', [i1_pos(1) i1_pos(2) + 0.03 i1_pos(3) 0.03], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 2, 'horizontalalignment', 'center');
i1_slider = uicontrol('style', 'slider', 'units', 'normalized', 'position', i1_pos);
i1_slider.Value = 0.25;
i1_jslider = findjobj(i1_slider);
i1_jslider.AdjustmentValueChangedCallback = {@i1, fig_2ns, i1_val};

% W1
w1_val = uicontrol('Style', 'text', 'String', num2str(w_init), 'units', 'normalized', 'position', [w1_pos(1) + w1_pos(3) w1_pos(2) 0.04 w1_pos(4)], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 5, 'horizontalalignment', 'center');
w1_title = uicontrol('Style', 'text', 'String', w_str, 'units', 'normalized', 'position', [w1_pos(1) w1_pos(2) + 0.03 w1_pos(3) 0.03], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 2, 'horizontalalignment', 'center');
w1_slider = uicontrol('style', 'slider', 'units', 'normalized', 'position', w1_pos);
w1_slider.Value = 2/30;
w1_jslider = findjobj(w1_slider);
w1_jslider.AdjustmentValueChangedCallback = {@w1, fig_2ns, w1_val};

% A2
a2_val = uicontrol('Style', 'text', 'String', num2str(a_init), 'units', 'normalized', 'position', [a2_pos(1) - 0.04 a2_pos(2) 0.04 a2_pos(4)], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 5, 'horizontalalignment', 'center');
a2_title = uicontrol('Style', 'text', 'String', a_str, 'units', 'normalized', 'position', [a2_pos(1) a2_pos(2) + 0.03 a2_pos(3) 0.03], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 2, 'horizontalalignment', 'center');
a2_slider = uicontrol('style', 'slider', 'units', 'normalized', 'position', a2_pos);
a2_slider.Value = a_init / 0.15;
a2_jslider = findjobj(a2_slider);
a2_jslider.AdjustmentValueChangedCallback = {@a2, fig_2ns, a2_val};

% B2
b2_val = uicontrol('Style', 'text', 'String', num2str(b_init), 'units', 'normalized', 'position', [b2_pos(1) - 0.04 b2_pos(2) 0.04 b2_pos(4)], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 5, 'horizontalalignment', 'center');
b2_title = uicontrol('Style', 'text', 'String', b_str, 'units', 'normalized', 'position', [b2_pos(1) b2_pos(2) + 0.03 b2_pos(3) 0.03], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 2, 'horizontalalignment', 'center');
b2_slider = uicontrol('style', 'slider', 'units', 'normalized', 'position', b2_pos);
b2_slider.Value = b_init / 0.5;
b2_jslider = findjobj(b2_slider);
b2_jslider.AdjustmentValueChangedCallback = {@b2, fig_2ns, b2_val};

% C2
c2_val = uicontrol('Style', 'text', 'String', num2str(c_init), 'units', 'normalized', 'position', [c2_pos(1) - 0.04 c2_pos(2) 0.04 c2_pos(4)], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 5, 'horizontalalignment', 'center');
c2_title = uicontrol('Style', 'text', 'String', c_str, 'units', 'normalized', 'position', [c2_pos(1) c2_pos(2) + 0.03 c2_pos(3) 0.03], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 2, 'horizontalalignment', 'center');
c2_slider = uicontrol('style', 'slider', 'units', 'normalized', 'position', c2_pos);
c2_slider.Value = 0.35;
c2_jslider = findjobj(c2_slider);
c2_jslider.AdjustmentValueChangedCallback = {@c2, fig_2ns, c2_val};

% D2
d2_val = uicontrol('Style', 'text', 'String', num2str(d_init), 'units', 'normalized', 'position', [d2_pos(1) - 0.04 d2_pos(2) 0.04 d2_pos(4)], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 5, 'horizontalalignment', 'center');
d2_title = uicontrol('Style', 'text', 'String', d_str, 'units', 'normalized', 'position', [d2_pos(1) d2_pos(2) + 0.03 d2_pos(3) 0.03], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 2, 'horizontalalignment', 'center');
d2_slider = uicontrol('style', 'slider', 'units', 'normalized', 'position', d2_pos);
d2_slider.Value = 0.2;
d2_jslider = findjobj(d2_slider);
d2_jslider.AdjustmentValueChangedCallback = {@d2, fig_2ns, d2_val};

% I2
i2_val = uicontrol('Style', 'text', 'String', num2str(noise_init), 'units', 'normalized', 'position', [i2_pos(1) - 0.04 i2_pos(2) 0.04 i2_pos(4)], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 5, 'horizontalalignment', 'center');
i2_title = uicontrol('Style', 'text', 'String', i_str, 'units', 'normalized', 'position', [i2_pos(1) i2_pos(2) + 0.03 i2_pos(3) 0.03], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 2, 'horizontalalignment', 'center');
i2_slider = uicontrol('style', 'slider', 'units', 'normalized', 'position', i2_pos);
i2_slider.Value = 0.25;
i2_jslider = findjobj(i2_slider);
i2_jslider.AdjustmentValueChangedCallback = {@i2, fig_2ns, i2_val};

% W2
w2_val = uicontrol('Style', 'text', 'String', num2str(w_init), 'units', 'normalized', 'position', [w2_pos(1) - 0.04 w2_pos(2) 0.04 w2_pos(4)], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 5, 'horizontalalignment', 'center');
w2_title = uicontrol('Style', 'text', 'String', w_str, 'units', 'normalized', 'position', [w2_pos(1) w2_pos(2) + 0.03 w2_pos(3) 0.03], 'FontName', special_font, 'backgroundcolor', fig_bg_col, 'fontsize', screen_size_constant - 2, 'horizontalalignment', 'center');
w2_slider = uicontrol('style', 'slider', 'units', 'normalized', 'position', w2_pos);
w2_slider.Value = 2/30;
w2_jslider = findjobj(w2_slider);
w2_jslider.AdjustmentValueChangedCallback = {@w2, fig_2ns, w2_val};

% Pause button
button_pause = uicontrol('Style', 'pushbutton', 'String', 'Pause', 'units', 'normalized', 'position', pause_button_pos);
set(button_pause, 'Callback', 'pause_button_press', 'FontSize', screen_size_constant, 'FontName', special_font)

% Stop button
button_stop = uicontrol('Style', 'pushbutton', 'String', 'Stop', 'units', 'normalized', 'position', stop_button_pos);
set(button_stop, 'Callback', 'stop_button_press', 'FontSize', screen_size_constant, 'FontName', special_font)


%% Runtime
nstep = 0;
pulse = timer('period', intended_timer_period, 'timerfcn', 'pulse_code', 'executionmode', 'fixedrate');
start(pulse)


%% Slider functions
function a1(hObject, ~, fig_design, a1_val)
n = double(get(hObject, 'Value'));
a = ((n + 100000) / 1000000) * 1;
a = 0 + a * 0.15;
fig_design.UserData(1) = a;
a1_val.String = num2str(round(a * 1000) / 1000);
end

function b1(hObject, ~, fig_design, b1_val)
n = double(get(hObject, 'Value'));
b = ((n + 100000) / 1000000) * 1;
b = 0 + b * 0.5;
fig_design.UserData(2) = b;
b1_val.String = num2str(round(b * 100) / 100);
end

function c1(hObject, ~, fig_design, c1_val)
n = double(get(hObject, 'Value'));
c = ((n + 100000) / 1000000) * 1;
c = -100 + c * 100;
fig_design.UserData(3) = c;
c1_val.String = num2str(round(c));
end

function d1(hObject, ~, fig_design, d1_val)
n = double(get(hObject, 'Value'));
d = ((n + 100000) / 1000000) * 1;
d = d * 10;
fig_design.UserData(4) = d;
d1_val.String = num2str(round(d * 10) / 10);
end

function i1(hObject, ~, fig_design, i1_val)
n = double(get(hObject, 'Value'));
i = ((n + 100000) / 1000000) * 1;
i = i * 20;
fig_design.UserData(5) = i;
i1_val.String = num2str(round(i * 10) / 10);
end

function w1(hObject, ~, fig_design, i1_val)
n = double(get(hObject, 'Value'));
w = ((n + 100000) / 1000000) * 1;
w = w * 30;
fig_design.UserData(6) = w;
i1_val.String = num2str(round(w));
end

function a2(hObject, ~, fig_design, a2_val)
n = double(get(hObject, 'Value'));
a = ((n + 100000) / 1000000) * 1;
a = 0 + a * 0.15;
fig_design.UserData(7) = a;
a2_val.String = num2str(round(a * 1000) / 1000);
end

function b2(hObject, ~, fig_design, b2_val)
n = double(get(hObject, 'Value'));
b = ((n + 100000) / 1000000) * 1;
b = 0 + b * 0.5;
fig_design.UserData(8) = b;
b2_val.String = num2str(round(b * 100) / 100);
end

function c2(hObject, ~, fig_design, c2_val)
n = double(get(hObject, 'Value'));
c = ((n + 100000) / 1000000) * 1;
c = -100 + c * 100;
fig_design.UserData(9) = c;
c2_val.String = num2str(round(c));
end

function d2(hObject, ~, fig_design, d2_val)
n = double(get(hObject, 'Value'));
d = ((n + 100000) / 1000000) * 1;
d = d * 10;
fig_design.UserData(10) = d;
d2_val.String = num2str(round(d * 10) / 10);
end

function i2(hObject, ~, fig_design, i2_val)
n = double(get(hObject, 'Value'));
i = ((n + 100000) / 1000000) * 1;
i = i * 20;
fig_design.UserData(11) = i;
i2_val.String = num2str(round(i * 10) / 10);
end

function w2(hObject, ~, fig_design, i1_val)
n = double(get(hObject, 'Value'));
w = ((n + 100000) / 1000000) * 1;
w = w * 30;
fig_design.UserData(12) = w;
i1_val.String = num2str(round(w));
end

