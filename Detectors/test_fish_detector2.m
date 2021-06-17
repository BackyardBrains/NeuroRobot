
cmap = cool;

input_video_name = 'hero55_small.MP4';
filename = input_video_name;
filename(strfind(input_video_name, '_')) = [];

vidReader = VideoReader(input_video_name);
vidWriter = VideoWriter('hero55_small_ai_alexnet_qi03_InitialLearnRate00025_NumStrongestRegions1000.mp4','MPEG-4');
open(vidWriter)

fig1 = figure(1);
clf
set(fig1, 'position', [2092 134 720 560], 'color', 'w')
% set(fig1, 'position', [200 134 720 560], 'color', 'w')
frame = read(vidReader, 1);
im1 = image(frame);
hold on
ti1 = title(horzcat('nframe = 0 of ', num2str(vidReader.NumFrames)));
% tx1 = text(100, 100, '', 'color', [0.94 0.2 0.07], 'FontName', 'Comic Book', 'fontsize', 20);

qi = 0.3;
yi = zeros(vidReader.NumFrames, 1);
zi = [];
clear pl

for nstep = 1:vidReader.NumFrames
    frame = read(vidReader, nstep);
    [bbox, score, label] = detect(trainedDetector, frame, 'NumStrongestRegions', 1000, 'threshold', qi, 'ExecutionEnvironment', 'gpu');
    [mscore, midx] = max(score);
    mbbox = bbox(midx, :);
    if ~isempty(mscore)
        yi(nstep) = mscore;
    end
    disp(num2str(nstep))
    im1.CData = frame;
    
%     if mscore > qi        
        
        x = bbox(score > qi,1) + bbox(score > qi,3)/2;
        y = bbox(score > qi,2) + bbox(score > qi,4)/2;                
        mx = mbbox(:,1) + mbbox(:,3)/2;
        my = mbbox(:,2) + mbbox(:,4)/2;     
        
        nboxes = length(x);
        prev_length = length(zi);
        zi(1 + prev_length : prev_length + nboxes) = 10;
        for nbox = 1:nboxes
            if score(nbox)
%             pl(prev_length + nbox).plt = plot(x, y, 'linestyle', 'none', 'color', [0.94 0.2 0.07], 'marker', 'o', 'markersize', 5);        
                pl(prev_length + nbox).plt = plot(x, y, 'linestyle', 'none', 'color', cmap(round(score(nbox)* 64), :), 'marker', 'o', 'markersize', 5);        
            end
        end
                        
%         plot(mx, my, 'linestyle', 'none', 'color', [0.94 0.2 0.07], 'marker', '.', 'markersize', 20);
%         tx1.String = horzcat('fish: ', num2str(round(mscore * 100)/100));
%         tx1.Position = [mx + 10 my - 3 0];
        
%     end
    
    for ii = 1:length(zi)
        zi(ii) = zi(ii) - 1;
        if zi(ii) < 1
            delete(pl(ii).plt)
        end
    end    
    
    ti1.String = horzcat(filename, ', nframe = ', num2str(nstep), ' of ', num2str(vidReader.NumFrames), ', mscore = ', num2str(round(mscore * 100)/100));
    drawnow
    
    imx = getframe(fig1);
    writeVideo(vidWriter, imx.cdata);

end

close(vidWriter)

