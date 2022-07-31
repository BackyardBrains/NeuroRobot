
% load('image_ds')
% load('imageIndex')

%%

nmatches = Inf;
queryROI = [1 1 226 126];
this_th = 0.99;

flag = 1;
while flag

    this_ind = randsample(20000, 1);
    
    img = readimage(image_ds, this_ind);
    [inds,similarity_scores] = retrieveImages(img, imageIndex, 'Metric', 'L1', 'NumResults', nmatches, 'ROI',queryROI);
    
    figure(1)
    clf
    subplot(2,3,1)
    image(img)
    title(horzcat('Query image ', num2str(this_ind)))
    


    if isempty(inds) || length(inds) == 1
        disp(horzcat('No matches at threshold ', num2str(this_th)))
    else
        subplot(2,3,[2:3, 5:6])
        montage(imageIndex.ImageLocation(inds))
        title(horzcat('Best ', num2str(length(inds)), ' matches'))
        subplot(2,3,4)
        histogram(similarity_scores)
        flag = 0;
    end
end
