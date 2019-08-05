
close all
clear

% File names
data_dir = 'C:\Users\Christopher Harris\Desktop\Video\';
file_name = 'VID_20190804_034752.mp4';
this_input_file = horzcat(data_dir, file_name);
audio_output_file = horzcat(data_dir, file_name(1:19), '_audio_out.wav');
video_output_file = horzcat(data_dir, file_name(1:19), '_video_out.mp4');

% Get audio
tic
[y,Fs] = audioread(this_input_file);
audiowrite(audio_output_file,y,Fs)
disp(horzcat('audio extracted in ', num2str(round(toc)), ' s'))

% Get video
tic
video_reader = VideoReader(this_input_file);
nframes = floor(video_reader.Duration * video_reader.FrameRate);
these_frames = zeros(video_reader.Height, video_reader.Width, 3, nframes, 'single');
for nframe = 1:nframes
    frame = readFrame(video_reader);
    these_frames(:,:,:,nframe) = frame;
end
disp(horzct('video extracted in ', num2str(round(toc)), ' s'))
tic
video_writer = VideoWriter(video_output_file, 'MPEG-4');
disp(horzct('video saved in ', num2str(round(toc)), ' s'))
