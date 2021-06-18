
cam_id = 2;
delete(imaqfind)
cmap = cool;
if ~exist('trainedDetector', 'var')
    load('rcnn2')
end
prepare_word

%% Create camera object
cam = videoinput('winvideo', cam_id);
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
hold on

%% Record video
qi = 0.4;
zi = [];
clear pl
nframe = 0;
superflag = 0;
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

    disp(num2str(nframe))

    x = bbox(score > qi,1) + bbox(score > qi,3)/2;
    y = bbox(score > qi,2) + bbox(score > qi,4)/2;                
    mx = mbbox(:,1) + mbbox(:,3)/2;
    my = mbbox(:,2) + mbbox(:,4)/2;     

    nboxes = length(x);
    prev_length = length(zi);
    zi(1 + prev_length : prev_length + nboxes) = 10;
    for nbox = nboxes:-1:1
        if score(nbox)
            pl(prev_length + nbox).plt = plot(x, y, 'linestyle', 'none', 'color', cmap(round(score(nbox)* 64), :), 'marker', 'o', 'markersize', 8, 'linewidth', 2);        
        end
    end

    for ii = 1:length(zi)
        zi(ii) = zi(ii) - 1;
        if zi(ii) < 1
            delete(pl(ii).plt)
        end
    end    
    
    ti1.String = horzcat('nframe = ', num2str(nframe), ', mscore = ', num2str(round(mscore * 100)/100), ', superflag = ', num2str(superflag));
    drawnow
    
    if ~isempty(mscore)
        if mscore > 0.8 && ~superflag
            superflag = 100;
            try
                gpt3_play
            catch
                disp('GTP fail')
                soundsc(this_wav, 16000);
            end
        end
    end
    if superflag
        superflag = superflag - 1;
    end
    
    writeVideo(vidWrite, frame);
    
end

flag = 1;
close(vidWrite)
close(fig1)
stop(cam)
