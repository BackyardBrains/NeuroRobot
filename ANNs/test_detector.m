
%% Single frame test
img = imread('.\Test data\frame_001.png');
[bbox, score, label] = detect(rcnn, img, 'MiniBatchSize', 32);
[score, idx] = max(score);
bbox = bbox(idx, :);
annotation = sprintf('%s: (Confidence = %f)', label(idx), score);
detectedImg = insertObjectAnnotation(img, 'rectangle', bbox, annotation);
figure
imshow(detectedImg)


%% Video test

figure(1)
clf
set(gcf, 'position', [2547 318 560 420])
ax_frame = axes('position', [0.02 0.1 0.96 0.84]);
show_frame = image(zeros(240, 320, 3));
set(gca, 'xtick', [], 'ytick', [])
title('Confidence = 0')
ax_score = axes('position', [0.02 0.02 0.47 0.06]);
set(gca, 'xtick', [], 'ytick', [])
ax_score.Color = [0 0 1];
button_stop = uicontrol('Style', 'pushbutton', 'String', 'Stop', 'units', 'normalized', 'position', [0.51 0.02 0.47 0.06]);
set(button_stop, 'Callback', 'stop_now = 1;', 'FontSize', 12, 'FontName', 'Arial', 'FontWeight', 'bold', 'BackgroundColor', [0.8 0.8 0.8])

stop_now = 0;
while ~stop_now
    trigger(vid)
    frame = getdata(vid);
    show_frame.CData = frame;
    [bbox, score, label] = detect(rcnn, frame, 'MiniBatchSize', 32);
    [score, idx] = max(score);
    if ~isempty(score)
        ax_score.Color = [0 score 1 - score];
        ax_frame.Title.String = horzcat('Confidence = ', num2str(round(score * 100)/100));
    else
        ax_score.Color = [0 0 1];
        ax_frame.Title.String = 'Confidence = 0';
    end
    pause(0.05)
end

close(1)

