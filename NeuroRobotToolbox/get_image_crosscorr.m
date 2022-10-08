queryROI = [1, 1, imdim - 1, imdim - 1];
xdata = zeros(nmedium, nmedium);
for nimage = 1:nmedium
    if ~rem(nimage, round(nmedium/100))
        disp(horzcat('Processing tuple ', num2str(nimage), ' of ', num2str(nmedium)))
    end
    img = readimage(image_ds_medium, nimage);
%     [inds,similarity_scores] = retrieveImages(img, imageIndex, 'Metric', 'L1', 'ROI', queryROI, 'NumResults', Inf);
    [inds,similarity_scores] = retrieveImages(img, imageIndex, 'Metric', 'cosine', 'ROI', queryROI, 'NumResults', Inf);
    xdata(nimage, inds) = similarity_scores;
end