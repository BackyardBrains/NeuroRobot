
close all
clear


% large_brain = 1;


% Get phone mp4 and laptop run data
data_dir = 'C:\Users\chris\Downloads\';
file_name = 'VID_20190805_133635.mp4';

start_time_in_sec = 16;
end_time_in_sec = 36;

this_input_file = horzcat(data_dir, file_name);
audio_output_file = horzcat(data_dir, file_name(1:19), '_audio_out.wav');
video_output_file = horzcat(data_dir, file_name(1:19), '_video_out.mp4');
brain_1_file_name = '2019-08-05-01-30-40-3040-Merlin.mat';
brain_2_file_name = '2019-08-05-01-32-26-3226-Mos.mat';
brain_1 = load(horzcat('C:\Users\chris\NeuroRobot\Matlab\Data\', brain_1_file_name));
brain_2 = load(horzcat('C:\Users\chris\NeuroRobot\Matlab\Data\', brain_2_file_name));
brain_1_name = brain_1_file_name(26:end-4);
brain_2_name = brain_2_file_name(26:end-4);
brain_selection_val = 2;
ms_per_step = 100;
nsteps_per_loop = ms_per_step * 10;
draw_synapse_strengths = 1;
draw_neuron_numbers = 1;
bfsize = 16;
% load_or_initialize_brain
    
    brain = brain_1.data.brain;
    nneurons = brain.nneurons;
    neuron_xys = brain.neuron_xys;
    connectome = brain.connectome;
    da_connectome = brain.da_connectome;
    if size(da_connectome, 3) == 2
        da_connectome(:,:,3) = zeros(size(connectome));
    end
    a_init = brain.a_init;
    b_init = brain.b_init;
    c_init = brain.c_init;
    d_init = brain.d_init;
    w_init = brain.w_init;
    a = brain.a;
    b = brain.b;
    cc = brain.c;
    d = brain.d;
    v = cc + 5 * randn(nneurons, 1);
    u = b .* v;
    spikes_loop = zeros(nneurons, ms_per_step * nsteps_per_loop);
    if isfield(brain, 'spikes_loop')
        brain = rmfield(brain, 'spikes_loop');
    end
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
    
gui_font_name = 'Comic Book';
gui_font_weight = 'normal';
contact_xys = [-1.2, 2.05; 1.2, 2.1; -2.08, -0.38; 2.14, -0.38; ...
    -0.05, 2.45; -1.9, 1.45; -1.9, 0.95; -1.9, -1.78; ...
    -1.9, -2.28; 1.92, 1.49; 1.92, 0.95; 1.92, -1.82; 1.92, -2.29];
ncontacts = size(contact_xys, 1);

% Prep brain video generation
fig1 = figure(1);
set(fig1, 'position', [100 140 1000 800] * 0.8);
brain_ax = axes('position', [0 0 1 1]);
im3 = flipud(255 - ((255 - imread('workspace.jpg'))));
image('CData',im3,'XData',[-3 3],'YData',[-3 3])
set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
axis([-3 3 -3 3.4])
hold on
text(0, 3.2, brain_1_name, 'FontName', gui_font_name, 'fontsize', 20, 'horizontalalignment', 'center', 'verticalalignment', 'middle')
draw_brain

% Get audio
tic
[y,Fs] = audioread(this_input_file);
y = y(start_time_in_sec*Fs:end_time_in_sec*Fs);
audiowrite(audio_output_file,y,Fs);
disp(horzcat('audio extracted in ', num2str(round(toc)), ' s'))


% Get video
tic
video_reader = VideoReader(this_input_file);
% nframes = floor(video_reader.Duration * video_reader.FrameRate);
nframes = (end_time_in_sec - start_time_in_sec) * 30;
these_frames = zeros(video_reader.Height, video_reader.Width, 3, nframes, 'uint8');
xfiring = brain_1.data.firing(:,1);
xx = linspace(start_time_in_sec * 30, end_time_in_sec * 30, 1+round((nframes/30) * 10));
cc = 1;
dd = 0;
for nframe = 1:end_time_in_sec * 30
    disp(horzcat(num2str(nframe), ' of ', num2str(end_time_in_sec * 30)))
    frame = readFrame(video_reader);
    if nframe >= xx(cc)
        disp(horzcat('collecting firing slice ', num2str(cc), ' (cc), at nframe', num2str(nframe)))
        xfiring = brain_1.data.firing(:,cc + (start_time_in_sec + 2.6) * 10);
        cc = cc + 1;
    end
    if nframe >= xx(1)
        draw_neuron_core.CData = [1 - xfiring 1 - (xfiring * 0.25) 1 - xfiring] .* neuron_cols;
        draw_neuron_edge.CData = [zeros(nneurons, 1) xfiring * 0.5 zeros(nneurons, 1)] .* neuron_cols;
    %     if bg_brain
    %         draw_neuron_core.CData(down_neurons, :) = repmat([0.85 0.85 0.85], [sum(down_neurons), 1]);
    %         draw_neuron_edge.CData(down_neurons, :) = repmat([0.4 0.4 0.4], [sum(down_neurons), 1]);
    %     end
        drawnow
        F = getframe(fig1);
    %     [X, Map] = frame2im(F);
        brain_1_im = F.cdata;
        brain_1_im = imresize(brain_1_im, [380 420]);
        frame(1:420, 1:460, :) = 255;
        frame(21:400, 21:440, :) = brain_1_im;
    
        % Brain 2
        frame(1:420, 1461:1920, :) = 255;
        frame(21:400, 1481:1900, :) = brain_1_im;
        
        % To frame stack
        dd = dd + 1;
        these_frames(:,:,:,dd) = frame;
    end
    
end
disp(horzcat('video extracted in ', num2str(round(toc)), ' s'))
tic
video_writer = VideoWriter(video_output_file, 'MPEG-4');
open(video_writer)
writeVideo(video_writer,these_frames)
close(video_writer)
disp(horzcat('video saved in ', num2str(round(toc)), ' s'))
