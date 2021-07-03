
close all
clear

%% Settings
input_video_name = 'C:\Users\chris\Downloads\fish1x.mp4';

%% Create video reader
vidRead = VideoReader(input_video_name);

%% Create video writer object
vidWrite = VideoWriter('C:\Users\chris\Downloads\fish1_small.mp4','MPEG-4');
open(vidWrite)

%% Record video
for nstep = 1:vidRead.NumFrames
    frame = read(vidRead, nstep);
    frame = frame(600:2000, 500:3200, :);
    frame = imresize(frame, 0.17);
    writeVideo(vidWrite, frame);
    disp(horzcat('nframe = ', num2str(nstep), ' of ', num2str(vidRead.NumFrames)))
end
close(vidWrite)
