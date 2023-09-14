
%% Get features and similarity scores

axes(unsup_out1_ax)
cla

this_msg = horzcat('Preparing to find features...');
tx2 = text(0.03, 0.5, this_msg);
drawnow
disp(this_msg)

small_inds = randsample(ntuples, nsmall);
medium_inds = randsample(ntuples, nmedium);
image_ds_small = subset(image_ds, small_inds);
image_ds_medium = subset(image_ds, medium_inds);
image_ds_small.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
image_ds_medium.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually

ps = parallel.Settings;
ps.Pool.AutoCreate = false;
ps.Pool.IdleTimeout = Inf;

this_msg = 'Finding features...';
tx2.String = this_msg;
drawnow
disp(this_msg)
bag = bagOfFeatures(image_ds_small, 'treeproperties', [2 bof_branching]);

this_msg = 'Creating image index...';
tx2.String = this_msg;
drawnow
disp(this_msg)
imageIndex = indexImages(image_ds_medium, bag);

this_msg = 'Getting similarity matrix...';
tx2.String = this_msg;
drawnow

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

avg_sim = mean(xdata(:));
this_msg = horzcat('Avg. similarity = ', num2str(avg_sim));
disp(this_msg)
tx2.String = horzcat(this_msg);
drawnow


%% Plot similarity matrix

axes(im_ax1)
imagesc(xdata, [0 0.75])
xlabel('Image')
ylabel('Image')
c = colorbar('location', 'manual', 'position', im_ax1_colb_pos);
title('Similarity scores')

axes(im_ax2)
histogram(xdata(:))
set(gca, 'yscale', 'log')
xlabel('Similarity score')
ylabel('Count')
title('Similarity data histogram')

drawnow
