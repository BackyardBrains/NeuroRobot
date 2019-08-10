
close all
clear

    
%% Get data
data_dir = 'C:\Users\Christopher Harris\Desktop\Neurorobot Video\';
file_name = 'VID_20190808_170046';
this_input_file = horzcat(data_dir, file_name, '.mp4');
audio_output_file = horzcat(data_dir, file_name(1:19), '_audio_out.wav');
video_output_file = horzcat(data_dir, file_name(1:19), '_video_out.mp4');
brain_dir = 'C:\Users\Christopher Harris\NeuroRobot\Matlab\Data\';

audio_hz = 8000;
firing_hz = 8;
Fs = 44100;

% brain_to_phone_lag = -50805;


%% Get video
tic
% start_time_in_sec = -(brain_to_phone_lag / audio_hz);
% video_reader = VideoReader(this_input_file, 'CurrentTime', start_time_in_sec);
video_reader = VideoReader(this_input_file);

i = 20;
% n_phone_frames = round(113.8880 * 29.9945);
n_phone_frames = round(i * 30);
these_frames = zeros(1080, 1920, 3, n_phone_frames, 'uint8');
nstep = 1;
for nframe = 1:n_phone_frames
    
    disp(horzcat('nframe ', num2str(nframe), ' of ', num2str(n_phone_frames)))
    
    % Get phone frame
    frame = readFrame(video_reader);
    
    % Insert brain frames into phone frame
    these_frames(:,:,:,nframe) = frame;
      
end


%%
x = these_frames;
these_frames = x;
% % these_frames(:,:,:,end-30:end) = [];
these_frames(:,:,:,1:14) = []; % The 15 here may still need a small adjust
video_writer = VideoWriter(video_output_file, 'MPEG-4');
video_writer.Quality = 100;
open(video_writer)
writeVideo(video_writer, these_frames)
close(video_writer)

% %% Get audio
[y,Fs] = audioread(this_input_file, [1 round(i*Fs)]);
y = y(:,1);
y(end-Fs/2+((1/30) * Fs):end) = [];
% y = y(round((start_time_in_sec*Fs):round(start_time_in_sec*Fs)+round(i*Fs)));
% y = y(1:round(i*Fs));
audiowrite(audio_output_file, y, Fs)

