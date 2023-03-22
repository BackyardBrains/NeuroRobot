
%% Get features and similarity scores

axes(ax2)

tx2 = text(0.03, 0.5, horzcat('preparing to find features...'));
drawnow

nsmall = 200;
nmedium = 500;

small_inds = randsample(ntuples, nsmall);
medium_inds = randsample(ntuples, nmedium);
image_ds_small = subset(image_ds, small_inds);
image_ds_medium = subset(image_ds, medium_inds);
image_ds_small.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
image_ds_medium.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually

ps = parallel.Settings;
ps.Pool.AutoCreate = false;
ps.Pool.IdleTimeout = Inf;

tx2.String = 'finding features...';
drawnow
bag = bagOfFeatures(image_ds_small, 'treeproperties', [2 50]);

tx2.String = 'creating image index...';
drawnow
imageIndex = indexImages(image_ds_medium, bag);

tx2.String = 'getting similarity matrix...';
drawnow
get_image_crosscorr

avg_sim = mean(xdata(:));
tx2.String = horzcat('avg. similarity = ', num2str(avg_sim));
drawnow


%% Plot similarity matrix

axes(im_ax1)
imagesc(xdata)
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

