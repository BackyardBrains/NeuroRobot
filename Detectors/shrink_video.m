
%% Settings
this_size = [227 227];
input_video_name = '.\videos\hero54.MP4';

%% Create video reader
vidRead = VideoReader(input_video_name);

%% Create video writer object
vidWrite = VideoWriter('hero54_small.mp4','MPEG-4');
open(vidWrite)

%% Record video
for nstep = 1:vidRead.NumFrames
    disp(horzcat('nframe = ', num2str(nstep), ' of ', num2str(vidRead.NumFrames)))
    frame = read(vidRead, nstep);
    frame = frame(701:1200, 1101:1600, :);
    frame = imresize(frame, this_size);
    writeVideo(vidWrite, frame);
end
close(vidWrite)
