
for nframe = 1:394
    
    filename = trainingData{nframe,1}{1,1};
    bbox = trainingData{nframe,2}{1,:};

    im = imread(filename);

    figure(1)
    clf
    set(gcf, 'position', [485 294 935 484]);

    image(im)
    hold on

    for nbox = 1:size(bbox, 1)
        rectangle('position', bbox(nbox, :), 'linewidth', 2, 'edgecolor', 'r')
    end

end