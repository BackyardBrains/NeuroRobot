%% Create camera object
cam = videoinput('winvideo', 1);
triggerconfig(cam, 'manual');
cam.TriggerRepeat = Inf;
cam.FramesPerTrigger = 1;
cam.ReturnedColorspace = 'rgb';
start(cam)

%% Create video writer object
vidWrite = VideoWriter('training_video.avi','Uncompressed AVI');
vidWrite.FrameRate = fps;
open(vidWrite)

%% Create UI
fig1 = figure(1);
clf
trigger(cam)
frame = getdata(cam, 1);
frame = imresize(frame, this_size);
im1 = image(frame);
ti1 = title(horzcat('nframe = 0 of ', num2str(nsteps)));

%% Record video
for nstep = 1:nsteps
    tic
    trigger(cam)
    frame = getdata(cam, 1);
    frame = imresize(frame, this_size);
    im1.CData = frame;
    ti1.String = horzcat('nframe = ', num2str(nstep), ' of ', num2str(nsteps));
    writeVideo(vidWrite, frame);
    while toc < 1/fps
        pause(0.01)
    end
end
close(vidWrite)
close(fig1)
stop(cam)
