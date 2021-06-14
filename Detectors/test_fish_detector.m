

% FISH DETECTOR
% By Backyard Brains


% delete(imaqfind)
% close all
% clear
% load('trainedDetector')


%% Settings
% fps = 10;
input_video_name = 'hero53_small.MP4';

%% Create video reader
vidReader = VideoReader(input_video_name);

%% Create video writer object3
vidWriter = VideoWriter('hero53_x.mp4','MPEG-4');
% vidWriter.FrameRate = fps;

%% Create UI
fig1 = figure(1);
clf
set(fig1, 'position', [1 41 1536 748])
frame = read(vidReader, 1);
im1 = image(frame);
hold on
ti1 = title(horzcat('nframe = 0 of ', num2str(vidReader.NumFrames)));
tx1 = text(100, 100, '', 'color', [0.94 0.2 0.07], 'FontName', 'Comic Book', 'fontsize', 20);
new_data_log = 0;

%% Record video
open(vidWriter)
qi = 0.5;
for nstep = 1:vidReader.NumFrames
    frame = read(vidReader, nstep);
    [bbox, score, label] = detect(trainedDetector, frame, 'NumStrongestRegions', 2000, 'threshold', 0, 'ExecutionEnvironment', 'gpu');
    [mscore, midx] = max(score);
    mbbox = bbox(midx, :);
    im1.CData = frame;
    if mscore > qi
        new_data_log = new_data_log + 1;
        
        x = bbox(score > qi,1) + bbox(score > qi,3)/2;
        y = bbox(score > qi,2) + bbox(score > qi,4)/2;        
        
        mx = mbbox(:,1) + mbbox(:,3)/2;
        my = mbbox(:,2) + mbbox(:,4)/2;        
        
        plot(x, y, 'linestyle', 'none', 'color', [0.94 0.2 0.07], 'marker', '.', 'markersize', 16);
        
        plot(mx, my, 'linestyle', 'none', 'color', [0.94 0.2 0.07], 'marker', '.', 'markersize', 20);
        tx1.String = horzcat('fish: ', num2str(round(mscore * 100)/100));
        tx1.Position = [mx + 10 my - 3 0];
        
    end
    ti1.String = horzcat('Fish Detector by Backyard Brains >>> nframe = ', num2str(nstep), ' of ', num2str(vidReader.NumFrames));
                
    drawnow
    imx = getframe(fig1);
    writeVideo(vidWriter, imx.cdata);

end
close(vidWriter)

