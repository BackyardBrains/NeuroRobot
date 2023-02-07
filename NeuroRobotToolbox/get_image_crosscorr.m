
disp('Getting similarity matrix (slow, be patient)...')
xdata = zeros(nmedium, nmedium);

for ntuple = 1:nmedium
    
    if ~rem(ntuple, round(nmedium/10))
        disp(horzcat('Processing tuple ', num2str(ntuple), ' of ', num2str(nmedium)))
    end
    img = readimage(image_ds_medium, ntuple);
    [inds,similarity_scores] = retrieveImages(img, imageIndex, 'Metric', 'L1', 'NumResults', Inf);
%     [inds,similarity_scores] = retrieveImages(img, imageIndex, 'Metric', 'cosine', 'NumResults', Inf);
    xdata(ntuple, inds) = similarity_scores;

end