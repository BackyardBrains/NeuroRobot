
%% Settings
fps = 10;
this_size = [288 512];
input_video_name = 'fish1.mp4';

%% Create video reader
v = VideoReader(input_video_name);

%% Create video writer object
vidWrite = VideoWriter('fish1_small.avi','Uncompressed AVI');
vidWrite.FrameRate = fps;
open(vidWrite)

%% Record video
for nstep = 1:v.NumFrames
    disp(horzcat('nframe = ', num2str(nstep)))
    frame = read(v, nstep);
    frame = imresize(frame, this_size);
    writeVideo(vidWrite, frame);
end
close(vidWrite)
