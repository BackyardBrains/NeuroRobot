
nims = size(trainingData, 1);
nframe = randsample(nims, 1);

filename = trainingData{nframe,1}{1,1};
bbox = trainingData{nframe,2}{1,:};
% cbox = trainingData{nframe,3}{1,:};

im = imread(filename);

figure(10)
clf
set(gcf, 'position', [485 294 935 484]);

image(im)
hold on

for nbox = 1:size(bbox, 1)
    rectangle('position', bbox(nbox, :), 'linewidth', 2, 'edgecolor', 'r')
end

% for nbox = 1:size(cbox, 1)
%     rectangle('position', cbox(nbox, :), 'linewidth', 2, 'edgecolor', 'g')
% end

[bbox, score, label] = detect(rcnn, im, 'NumStrongestRegions', 500, 'MiniBatchSize', 128);

[mscore, mind] = max(score);

if ~isempty(mind)
    title(horzcat('nframe: ', num2str(nframe), ', score: ', num2str(mscore)))
    rectangle('position', bbox(mind, :), 'linewidth', 2, 'edgecolor', [1 0.5 0]);
    disp(label(mind))
else
    title(horzcat('nframe: ', num2str(nframe), ', label: ', 'No label'))
    disp('No label')
end

