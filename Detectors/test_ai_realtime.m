
% %% Create video writer
% vidWrite = VideoWriter(ai_video_filename,'MPEG-4');
% open(vidWriter)

%% Create camera object
cam = videoinput('winvideo', 1);
triggerconfig(cam, 'manual');
cam.TriggerRepeat = Inf;
cam.FramesPerTrigger = 1;
cam.ReturnedColorspace = 'rgb';
start(cam)

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
hold on
loc1 = plot(10, 10, 'markersize', 20, 'color', [0.8 0.4 0.2], 'marker', '.', 'linestyle', 'none');
txt1 = text(10, 10, 'hat: 0');

%% Get video
qi = 0.3;
yi = zeros(vidReader.NumFrames, 1);
zi = [];
clear pl

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
    
    [bbox, score, label] = detect(trainedDetector, frame, 'NumStrongestRegions', 500, ...
        'threshold', qi, 'ExecutionEnvironment', 'gpu', 'MiniBatchSize', 128);
    [mscore, midx] = max(score);
    mbbox = bbox(midx, :);
    if ~isempty(mscore)
        yi(nframe) = mscore;
    end
    disp(num2str(nframe))

    x = bbox(score > qi,1) + bbox(score > qi,3)/2;
    y = bbox(score > qi,2) + bbox(score > qi,4)/2;                
    mx = mbbox(:,1) + mbbox(:,3)/2;
    my = mbbox(:,2) + mbbox(:,4)/2;     

    nboxes = length(x);
    prev_length = length(zi);
    zi(1 + prev_length : prev_length + nboxes) = 10;
    for nbox = 1:nboxes
        pl(prev_length + nbox).plt = plot(x, y, 'linestyle', 'none', 'color', [0.94 0.2 0.07], 'marker', 'o', 'markersize', 5);        
    end

    loc1.XData = mx;
    loc1.YData = my;
    tx1.String = horzcat('fish: ', num2str(round(mscore * 100)/100));
    tx1.Position = [mx + 10 my - 3 0];
    
    for ii = 1:length(zi)
        zi(ii) = zi(ii) - 1;
        if zi(ii) < 1
            delete(pl(ii).plt)
        end
    end    
    
    ti1.String = horzcat(filename, ', nframe = ', num2str(nstep), ' of ', num2str(vidReader.NumFrames), ', mscore = ', num2str(round(mscore * 100)/100));
    drawnow
    
    imx = getframe(fig1);
    writeVideo(vidWrite, imx.cdata);

end

close(vidWrite)
close(fig1)
stop(cam)

