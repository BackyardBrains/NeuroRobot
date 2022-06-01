
% imgSet = imageSet('.\Experiences\Recording_6\');
% MemImages_tocall = indexImages(imgSet); 
% testSet = imageSet('.\Experiences\Recording_7\');

xdata = zeros(imgSet.Count, testSet.Count);
for id = 1:testSet.Count
    disp(num2str(id/imgSet.Count))
    large_frame = readimage(testSet, id);
    [IDs,scores]=retrieveImages(large_frame, MemImages_tocall, 'NumResults', Inf);
    if ~isempty(IDs)
        xdata(IDs, id) = scores;
    end
end

