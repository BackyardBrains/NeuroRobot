
close all
clear

% Get data
data_dir = 'C:\Users\Christopher Harris\Desktop\Neurorobot Video\';
file_name = '.mp4';
this_input_file = horzcat(data_dir, file_name);
audio_output_file = horzcat(data_dir, file_name(1:19), '_audio_out.wav');
video_output_file = horzcat(data_dir, file_name(1:19), '_video_out.mp4');
brain_1_data = load('C:\Users\Christopher Harris\NeuroRobot\Matlab\Data\2019-08-06-05-13-58-1358-Listener.mat');
brain_2_data = load('C:\Users\Christopher Harris\NeuroRobot\Matlab\Data\2019-08-06-05-13-58-1358-Listener.mat');

% Prepare
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

% Unpack brain
brain = brain_1_data.data.brain;
nneurons = brain.nneurons;
neuron_xys = brain.neuron_xys;
connectome = brain.connectome;
da_connectome = brain.da_connectome;
spikes_loop = zeros(nneurons, ms_per_step * nsteps_per_loop);
neuron_contacts = brain.neuron_contacts;
vis_prefs = brain.vis_prefs;
dist_prefs = brain.dist_prefs;
try
    audio_prefs = brain.audio_prefs;
catch
    audio_prefs = zeros(nneurons, 1);
end
neuron_cols = brain.neuron_cols;
network_ids = brain.network_ids;
da_rew_neurons = brain.da_rew_neurons;
try
    neuron_tones = brain.neuron_tones;
catch
    neuron_tones = zeros(nneurons, 1);
end
nnetworks = length(unique(network_ids)) + 1;
try
    network = brain.network;
catch
    for nnetwork = 1:nnetworks
        network(nnetwork).null = []; % Does this even have to be initialized?
    end
end
try
    network_drive = brain.network_drive;
    if isempty(network_drive) || size(network_drive, 1) < nnetworks || size(network_drive, 2) == 2
        network_drive = zeros(nnetworks, 3); 
    end
catch
    network_drive = zeros(nnetworks, 3); 
end
try
    bg_neurons = brain.bg_neurons;
catch
    bg_neurons = zeros(nneurons, 1);
end
down_neurons = false(nneurons, 1);
firing = brain_1_data.data.firing;
xfiring = firing(:,1);

% Get audio
[y,Fs] = audioread(this_input_file);
audiowrite(audio_output_file,y,Fs)
these_samples = round(linspace(1, length(y), round(length(y) * (8000 / 44100))));
phone_audio = y(these_samples, 1);
brain_1_audio = brain_1_data.data.audio;

% Get audio lags
[c_b1p, lag_b1p] = xcorr(brain_1_audio, phone_audio);
[~, j_b1p] = max(c_b1p);
brain_1_lag = lag_b1p(j_b1p);

% [c_b2p, lag_b2p] = xcorr(brain_2_audio, phone_audio);
% [~, j_b2p] = max(c_b2p);
% brain_2_lag = lag_b2p(j_b2p);

% Align the two brain datasets here

% % Test audio lags
% a = 60001;
% b = 80000;
% soundsc(brain_1_audio(a + brain_1_lag:b + brain_1_lag), 8000)
% soundsc(brain_2_audio(a + brain_2_lag:b + brain_2_lag), 8000)

% Prep the plot
fig1 = figure(1);
clf
set(fig1, 'position', [1000 100 800 640])
brain_ax = axes('position', [0 0 1 1]);
image('CData',im,'XData',[-3 3],'YData',[-3 3])
set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
axis([-3 3 -3.5 3])
hold on 
draw_brain

% Get video
tic
start_time_in_sec = brain_1_lag / 8000;
video_reader = VideoReader(this_input_file, 'CurrentTime', start_time_in_sec);
[i, j] = min([length(phone_audio) - (start_time_in_sec * 8000), length(brain_1_audio)]);
n_phone_frames = floor((i / 8000) * 30);
n_spike_steps = floor((i / 8000) * 10);
spike_steps_in_frames = round(linspace(1, n_phone_frames, n_spike_steps));
nstep = 1;
for nframe = 1:n_phone_frames
    
    disp(horzcat('nframe ', num2str(nframe)))
    
    % Get phone frame
    frame = readFrame(video_reader);
    
    % Get firing patterns
    if nframe > spike_steps_in_frames(nstep)
        xfiring = firing(:,nstep);
        disp(horzcat('nstep ', num2str(nstep)))
        nstep = nstep + 1;
    end
    
    % Update brains
    draw_neuron_core.CData = [1 - xfiring 1 - (xfiring * 0.25) 1 - xfiring] .* neuron_cols;
    draw_neuron_edge.CData = [zeros(nneurons, 1) xfiring * 0.5 zeros(nneurons, 1)] .* neuron_cols;
    if bg_brain
        draw_neuron_core.CData(down_neurons, :) = repmat([0.85 0.85 0.85], [sum(down_neurons), 1]);
        draw_neuron_edge.CData(down_neurons, :) = repmat([0.4 0.4 0.4], [sum(down_neurons), 1]);
    end
    
    % Insert brain frames in phone frame
    frame(1:440, 1:460, :) = 255;
    frame(21:420, 21:440, :) = getframe(fig1);
    
    % Frame 2
    frame(1:440, 1461:1920, :) = 255;
    frame(21:420, 1481:1900, :) = getframe(fig1);
    
    % Insert brain frames into phone frame
    these_frames(:,:,:,nframe) = frame;
    
end

disp(horzct('video extracted in ', num2str(round(toc)), ' s'))
tic
video_writer = VideoWriter(video_output_file, 'MPEG-4');
disp(horzct('video saved in ', num2str(round(toc)), ' s'))
