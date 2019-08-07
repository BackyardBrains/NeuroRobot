
close all
clear

profile clear
profile on
    
%% Get data
data_dir = 'C:\Users\Christopher Harris\Desktop\Neurorobot Video\';
file_name = 'VID_20190807_163619';
this_input_file = horzcat(data_dir, file_name, '.mp4');
audio_output_file = horzcat(data_dir, file_name(1:19), '_audio_out.wav');
video_output_file = horzcat(data_dir, file_name(1:19), '_video_out.mp4');
brain_dir = 'C:\Users\Christopher Harris\NeuroRobot\Matlab\Data\';
brain(1).file_name = '2019-08-07-04-35-27-3527-Crimson36';
brain(2).file_name = '2019-08-07-04-35-29-3529-Crimson25';
brain_data(1) = load(horzcat(brain_dir, brain(1).file_name, '.mat'));
brain_data(2) = load(horzcat(brain_dir, brain(2).file_name, '.mat'));
brain_name(1).name = brain(1).file_name(26:end);
brain_name(2).name = brain(2).file_name(26:end);

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
these_samples = round(linspace(1, length(y), round(length(y) * (8000 / 44100))));
phone_audio = y(these_samples, 1);
brain_1_audio = bandpass(brain_data(1).data.audio, [1000 3000], 8000);
brain_2_audio = bandpass(brain_data(2).data.audio, [1000 3000], 8000);

%% Synchronize
[c, lag] = xcorr(brain_1_audio, brain_2_audio);
[~, j] = max(c);
brain_1_to_2_lag = lag(j);

if brain_1_to_2_lag > 0
    brain_1_audio(1:brain_1_to_2_lag) = [];
    brain_data(1).data.firing(:,1:round(brain_1_to_2_lag / 800)) = [];
else
    brain_2_audio(1:-brain_1_to_2_lag) = []; % Not tested
    brain_data(2).data.firing(:,1:round(-brain_1_to_2_lag / 800)) = [];  
end

[c, lag] = xcorr(brain_1_audio, brain_2_audio);
[~, j] = max(c);
brain_1_to_2_lag_after = lag(j);
if brain_1_to_2_lag_after ~= 0
    error('Brain audio files did not align properly')
end

[c, lag] = xcorr(brain_1_audio, phone_audio);
[~, j] = max(c);
brain_to_phone_lag = lag(j);
if brain_to_phone_lag > 0
    error('Brain recording appears to have started before phone recording')
end

if brain_1_to_2_lag > 0
    error('Brain recording appears to have started before phone recording')
else
    y(1:round(-(brain_to_phone_lag / 8000) * 44100)) = [];
end

audiowrite(audio_output_file,y,Fs)

% % Test audio lags
% a = 1;
% b = 40000;
% soundsc(brain_1_audio(a:b), 8000)
% soundsc(brain_2_audio(a:b), 8000)
% soundsc(phone_audio(a - brain_1_to_phone_lag: b - brain_1_to_phone_lag), 8000)

%% Prep the plot
fig(1) = figure(1);
clf
set(fig(1), 'position', [2120 100 800 640])
brain_ax = axes('position', [0 0 1 1]);
image('CData',im,'XData',[-3 3],'YData',[-3 3])
set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
axis([-3 3 -3.5 3])
hold on 
brain = brain_data(1).data.brain;
read_brain
nbrain = 1;
draw_brain_for_movies
xplot(1).this_text = text(0, -3.3, brain_name(1).name, 'fontsize', 34, 'fontname', gui_font_name, 'horizontalalignment', 'center', 'verticalalignment', 'middle');

fig(2) = figure(2);
clf
set(fig(2), 'position', [2960 200 800 640])
brain_ax = axes('position', [0 0 1 1]);
image('CData',im,'XData',[-3 3],'YData',[-3 3])
set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
axis([-3 3 -3.5 3])
hold on 
brain = brain_data(2).data.brain;
read_brain
nbrain = 2;
draw_brain_for_movies
xplot(2).this_text = text(0, -3.25, brain_name(2).name, 'fontsize', 30, 'fontname', gui_font_name, 'horizontalalignment', 'center', 'verticalalignment', 'middle');

%% Get video
tic
start_time_in_sec = -(brain_to_phone_lag / 8000);
video_reader = VideoReader(this_input_file, 'CurrentTime', start_time_in_sec);
[i, j] = min([(length(phone_audio) / 8000) - start_time_in_sec, length(brain_data(1).data.firing) / 10, length(brain_data(2).data.firing) / 10]);
n_phone_frames = round(i * 30);
n_spike_steps = round(i * 10);
this_adjust = 0; % Custom sync (2 s * 30 fps)
spike_steps_in_frames = round(linspace(1 + this_adjust, n_phone_frames, n_spike_steps));
these_frames = zeros(1080, 1920, 3, n_phone_frames, 'uint8');
nstep = 1;
for nframe = 1:n_phone_frames
    
    disp(horzcat('nframe ', num2str(nframe)))
    
    % Get phone frame
    frame = readFrame(video_reader);
    
    % Get brain frames
    for nbrain = 1:2
        
        brain = brain_data(nbrain).data.brain;
        read_brain
        firing = brain_data(nbrain).data.firing;
        xfiring = firing(:,nstep);
        if nstep < 50
            xfiring = false(size(xfiring));
        end
        
        figure(nbrain)
        xplot(nbrain).draw_neuron_core.CData = [1 - xfiring 1 - (xfiring * 0.25) 1 - xfiring] .* neuron_cols;
        xplot(nbrain).draw_neuron_edge.CData = [zeros(nneurons, 1) xfiring * 0.5 zeros(nneurons, 1)] .* neuron_cols;
%         if bg_brain
%             draw_neuron_core.CData(down_neurons, :) = repmat([0.85 0.85 0.85], [sum(down_neurons), 1]);
%             draw_neuron_edge.CData(down_neurons, :) = repmat([0.4 0.4 0.4], [sum(down_neurons), 1]);
%         end

        delete(xplot(nbrain).this_text)
        xplot(nbrain).this_text = text(0, -3.3, brain_name(nbrain).name, 'fontsize', 34, 'fontname', gui_font_name, 'horizontalalignment', 'center', 'verticalalignment', 'middle');
        
        % Need to clean all the other things at the beginning of draw_brain
        drawnow
        
        if nbrain == 1
            % Insert brain frames in phone frame
            frame(1:440, 1:480, :) = 255;
            this_frame = getframe(fig(1));
            frame(21:420, 21:460, :) = imresize(this_frame.cdata, [400 440]);
    
        else
            % Frame 2
            frame(1:440, 1441:1920, :) = 255;
            this_frame = getframe(fig(2));
            frame(21:420, 1461:1900, :) = imresize(this_frame.cdata, [400 440]);
        end
    end
    
    % Insert brain frames into phone frame
    these_frames(:,:,:,nframe) = frame;
    
    % Step
    if nframe == spike_steps_in_frames(nstep)
        nstep = nstep + 1;
        disp(horzcat('nstep ', num2str(nstep)))
    end    
    
end

disp(horzcat('video extracted in ', num2str(round(toc)), ' s'))
tic
video_writer = VideoWriter(video_output_file, 'MPEG-4');
open(video_writer)
writeVideo(video_writer, these_frames)
close(video_writer)
disp(horzcat('video saved in ', num2str(round(toc)), ' s'))

profile off
profile viewer
