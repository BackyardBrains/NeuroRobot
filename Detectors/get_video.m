
delete(imaqfind)

%% Create camera object
cam = videoinput('winvideo', 1);
triggerconfig(cam, 'manual');
cam.TriggerRepeat = Inf;
cam.FramesPerTrigger = 1;
cam.ReturnedColorspace = 'rgb';
start(cam)

%% Create video writer object
if exist('vidWrite', 'var')
    close(vidWrite)
end
vidWrite = VideoWriter(raw_video_filename, 'MPEG-4');
vidWrite.FrameRate = fps;
open(vidWrite)

%% Get first frame
trigger(cam)
frame = getdata(cam, 1);
frame = frame(:, 281:1000, :);
frame = imresize(frame, net_input_size);

%% Create UI
fig1 = figure(1);
clf
set(gcf, 'position', [280 60 920 700], 'color', 'w')
ax_frame = axes('position', [0.02 0.1 0.96 0.86]);
im = image(frame);
set(gca, 'xtick', [], 'ytick', [])
flag = 1;
button_stop = uicontrol('Style', 'pushbutton', 'String', 'Stop', 'units', 'normalized', 'position', [0.02 0.02 0.96 0.06]);
set(button_stop, 'Callback', 'flag = 0;', 'FontSize', 12, 'FontName', 'Comic Book', 'FontWeight', 'bold', 'BackgroundColor', [0.8 0.8 0.8])
ti1 = title('Preparing...');

%% Record video
nframe = 0;
while flag
    tic
    nframe = nframe + 1;
    trigger(cam)
    frame = getdata(cam, 1);
    frame = frame(:, 281:1000, :);
    frame = imresize(frame, net_input_size);
    im.CData = frame;
    ti1.String = horzcat('Recording ', raw_video_filename(1:end-4), ', nframe = ', num2str(nframe));
    writeVideo(vidWrite, frame);    
    while toc < 1/fps
        pause(0.01)
    end
end
flag = 1;
close(vidWrite)
close(fig1)
stop(cam)
