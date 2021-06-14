
%% Create camera object
cam = videoinput('winvideo', 1);
triggerconfig(cam, 'manual');
cam.TriggerRepeat = Inf;
cam.FramesPerTrigger = 1;
cam.ReturnedColorspace = 'rgb';
start(cam)

%% Create UI
fig1 = figure(1);
clf
trigger(cam)
frame = getdata(cam, 1);
frame = imresize(frame, this_size);
im1 = image(frame);
hold on
loc1 = plot(10, 10, 'markersize', 20, 'color', [0.8 0.4 0.2], 'marker', '.', 'linestyle', 'none');
ti1 = title(horzcat('nframe = 0 of ', num2str(nsteps)));
txt1 = text(10, 10, 'hat: 0');

%% Record video
for nstep = 1:nsteps
    tic
    trigger(cam)
    frame = getdata(cam, 1);
    frame = imresize(frame, this_size);
    [bbox, score] = detect(trainedDetector, frame, 'NumStrongestRegions', 100, 'threshold', 0, 'ExecutionEnvironment', 'gpu');
    [score, idx] = max(score);
    bbox = bbox(idx, :);
    im1.CData = frame;
    loc1.XData = bbox(1) + bbox(3)/2;
    loc1.YData = bbox(2) + bbox(4)/2;
    ti1.String = horzcat('nframe = ', num2str(nstep), ' of ', num2str(nsteps));
    txt1.Position = [bbox(1) + bbox(3)/2 bbox(2) + bbox(4)/2 0];
    txt1.String = horzcat('hat: ', num2str(round(score * 100)/100));
    while toc < 1/fps
        pause(0.01)
    end
end
