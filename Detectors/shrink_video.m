
%% Settings
nframes = 8000;
this_size = [288 512];
input_video_name = 'C:\Users\Christopher Harris\Videos\hero52.MP4';

%% Create video reader
vidRead = VideoReader(input_video_name);

%% Create video writer object
vidWrite = VideoWriter('hero52_small.mp4','MPEG-4');
open(vidWrite)

%% Record video
for nstep = 1:nframes
    disp(horzcat('nframe = ', num2str(nstep), ' of ', num2str(vidRead.NumFrames)))
    frame = read(vidRead, nstep);
    frame = frame(501:(288*3+500), 501:(512*3+501), :);
    frame = imresize(frame, this_size);
    writeVideo(vidWrite, frame);
end
close(vidWrite)
