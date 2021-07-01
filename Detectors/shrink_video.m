
%% Settings
this_size = [227 227];
input_video_name = '.\videos\fishX1.MP4';

%% Create video reader
vidRead = VideoReader(input_video_name);

%% Create video writer object
vidWrite = VideoWriter('.\videos\fishX1_small.mp4','MPEG-4');
open(vidWrite)

%% Record video
for nstep = 1:vidRead.NumFrames
    frame = read(vidRead, nstep);
    frame = frame(701:1900, 501:3200, :);
%     frame = imresize(frame, this_size);
    frame = imresize(frame, 0.2);
    writeVideo(vidWrite, frame);
    disp(horzcat('nframe = ', num2str(nstep), ' of ', num2str(vidRead.NumFrames)))
end
close(vidWrite)
