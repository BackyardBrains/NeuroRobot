
%% Get features and similarity scores
axes(ml_train1_status)
cla

this_msg = horzcat('Finding features...');
tx2 = text(0.03, 0.5, this_msg, 'fontsize', bfsize + 4);
drawnow
disp(this_msg)

tiny_inds = randsample(ntuples, 99);
small_inds = randsample(ntuples, nsmall);
medium_inds = randsample(ntuples, nmedium);
image_ds_tiny = subset(image_ds, tiny_inds);
image_ds_small = subset(image_ds, small_inds);
image_ds_medium = subset(image_ds, medium_inds);

try
    ps = parallel.Settings;
    ps.Pool.AutoCreate = false;
    ps.Pool.IdleTimeout = Inf;
catch
    disp('no gpu (ml_get_similarity)')
end

axes(im_ax1)
montage(image_ds_tiny)
title('Example images from the dataset')
drawnow

bag = bagOfFeatures(image_ds_small, 'treeproperties', [2 bof_branching], 'BlockWidth', 64);

this_msg = 'Creating image index...';
tx2.String = this_msg;
drawnow
disp(this_msg)

imageIndex = indexImages(image_ds_medium, bag);

this_msg = 'Getting similarity matrix...';
tx2.String = this_msg;
drawnow
disp(this_msg)

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

avg_sim = mean(xdata(:));
this_msg = horzcat('Avgerage image similarity = ', num2str(avg_sim));
disp(this_msg)
tx2.String = horzcat(this_msg);
drawnow


%% Plot similarity matrix
axes(im_ax1)
histogram(xdata(:), [0 0.5])
set(gca, 'yscale', 'log')
title('Image similarity scores')

drawnow
