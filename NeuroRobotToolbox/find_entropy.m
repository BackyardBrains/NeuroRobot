
% imgSet = imageSet('.\Experiences\Recording_6\');
% MemImages_tocall = indexImages(imgSet); 
% testSet = imageSet('.\Experiences\Recording_7\');

for ii = 1:1000
    id = randsample(testSet.Count, 1);
    large_frame = readimage(testSet, id);
    [IDs,scores]=retrieveImages(large_frame,MemImages_tocall,'NumResults',Inf);
    if ~isempty(IDs) && scores(1) > 0.2
        closest_match=readimage(imgSet, IDs(1));
        figure(1)
        clf
        subplot(2,1,1)
        imshow(large_frame)
        subplot(2,1,2)
        imshow(closest_match)
        title(horzcat(num2str(scores(1))))
        pause
    end
end

