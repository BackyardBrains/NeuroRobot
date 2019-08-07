
close all
clear

%% Get data
data_dir = 'C:\Users\Christopher Harris\Desktop\Neurorobot Video\';
file_name = 'VID_20190807_113430';
this_input_file = horzcat(data_dir, file_name, '.mp4');
audio_output_file = horzcat(data_dir, file_name(1:19), '_audio_out.wav');
video_output_file = horzcat(data_dir, file_name(1:19), '_video_out.mp4');
brain_dir = 'C:\Users\Christopher Harris\NeuroRobot\Matlab\Data\';
brain_1_file_name = '2019-08-07-10-21-21-2121-Signet';
brain_2_file_name = '2019-08-07-10-21-25-2125-Moinet';
brain_data(1) = load(horzcat(brain_dir, brain_1_file_name, '.mat'));
brain_data(2) = load(horzcat(brain_dir, brain_2_file_name, '.mat'));

%% Prepare
ms_per_step = 100;
nsteps_per_loop = 10;
draw_neuron_numbers = 1;
draw_synapse_strengths = 1;
bfsize = 18;
bg_brain = 1;
gui_font_name = 'Comic Book';
gui_font_weight = 'normal';
im = flipud(255 - ((255 - imread('workspace.jpg'))));
fig_bg_col = [0.94 0.94 0.94];
contact_xys = [-1.2, 2.05; 1.2, 2.1; -2.08, -0.38; 2.14, -0.38; ...
    -0.05, 2.45; -1.9, 1.45; -1.9, 0.95; -1.9, -1.78; ...
    -1.9, -2.28; 1.92, 1.49; 1.92, 0.95; 1.92, -1.82; 1.92, -2.29];
ncontacts = size(contact_xys, 1);

%% Get audio
[y,Fs] = audioread(this_input_file);
audiowrite(audio_output_file,y,Fs)
these_samples = round(linspace(1, length(y), round(length(y) * (8000 / 44100))));
phone_audio = y(these_samples, 1);
brain_1_audio = brain_data(1).data.audio;
brain_2_audio = brain_data(2).data.audio;

%% Synchronize
[c, lag] = xcorr(brain_1_audio, brain_2_audio);
[~, j] = max(c);
brain_1_to_2_lag = lag(j);

if brain_1_to_2_lag > 0
    brain_1_audio(1:brain_1_to_2_lag) = [];
    brain_data(nbrain).data.firing(:,1:round(brain_1_to_2_lag / 800)) = [];
else
    brain_2_audio(1:-brain_1_to_2_lag) = []; % Not tested
    brain_data(nbrain).data.firing(:,1:round(-brain_1_to_2_lag / 800)) = [];  
end

[c, lag] = xcorr(brain_1_audio, phone_audio);
[~, j] = max(c);
brain_1_to_phone_lag = lag(j);

% Test audio lags
a = 1;
b = 40000;
soundsc(brain_1_audio(a + brain_1_to_2_lag:b + brain_1_to_2_lag), 8000)
soundsc(brain_2_audio(a:b), 8000)

% Prep the plot
fig(1) = figure(1);
clf
set(fig(1), 'position', [1000 100 800 640])
brain_ax = axes('position', [0 0 1 1]);
image('CData',im,'XData',[-3 3],'YData',[-3 3])
set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
axis([-3 3 -3.5 3])
hold on 
draw_brain

fig(2) = figure(2);
clf
set(fig(2), 'position', [1100 200 800 640])
brain_ax = axes('position', [0 0 1 1]);
image('CData',im,'XData',[-3 3],'YData',[-3 3])
set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
axis([-3 3 -3.5 3])
hold on 
draw_brain

% Get video
tic
start_time_in_sec = brain_1_to_phone_lag / 8000;
video_reader = VideoReader(this_input_file, 'CurrentTime', start_time_in_sec);
[i, j] = min([length(phone_audio) - (start_time_in_sec * 8000), length(brain_1_audio)]);
n_phone_frames = floor((i / 8000) * 30);
n_spike_steps = floor((i / 8000) * 10);
spike_steps_in_frames = round(linspace(1, n_phone_frames, n_spike_steps));
nstep = 0;
for nframe = 1:n_phone_frames
    
    disp(horzcat('nframe ', num2str(nframe)))
    
    % Get phone frame
    frame = readFrame(video_reader);
    
    % Get brain frames
    if nframe == spike_steps_in_frames(nstep)
        nstep = nstep + 1;
        disp(horzcat('nstep ', num2str(nstep)))
    end
    for nbrain = 1:2
        
        brain = brain_data(nbrain).data.brain;
        read_brain
        firing = brain_data(nbrain).data.firing;
        xfiring = firing(:,nstep);
        
        figure(nbrain)
        draw_neuron_core.CData = [1 - xfiring 1 - (xfiring * 0.25) 1 - xfiring] .* neuron_cols;
        draw_neuron_edge.CData = [zeros(nneurons, 1) xfiring * 0.5 zeros(nneurons, 1)] .* neuron_cols;
%         if bg_brain
%             draw_neuron_core.CData(down_neurons, :) = repmat([0.85 0.85 0.85], [sum(down_neurons), 1]);
%             draw_neuron_edge.CData(down_neurons, :) = repmat([0.4 0.4 0.4], [sum(down_neurons), 1]);
%         end
        
    end
    
    % Insert brain frames in phone frame
    frame(1:440, 1:460, :) = 255;
    frame(21:420, 21:440, :) = getframe(fig(1));
    
    % Frame 2
    frame(1:440, 1461:1920, :) = 255;
    frame(21:420, 1481:1900, :) = getframe(fig(2));
    
    % Insert brain frames into phone frame
    these_frames(:,:,:,nframe) = frame;
    
end

disp(horzct('video extracted in ', num2str(round(toc)), ' s'))
tic
video_writer = VideoWriter(video_output_file, 'MPEG-4');
disp(horzct('video saved in ', num2str(round(toc)), ' s'))
