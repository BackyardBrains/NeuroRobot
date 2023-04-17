
%% Get features and similarity scores

axes(ax2)

this_msg = horzcat('preparing to find features...');
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

this_msg = 'finding features...';
tx2.String = this_msg;
drawnow
disp(this_msg)
bag = bagOfFeatures(image_ds_small, 'treeproperties', [2 bof_branching]);

this_msg = 'creating image index...';
tx2.String = this_msg;
drawnow
disp(this_msg)
imageIndex = indexImages(image_ds_medium, bag);

this_msg = 'getting similarity matrix...';
tx2.String = this_msg;
drawnow
disp(this_msg)
get_image_crosscorr

% ml_dist_adjust

avg_sim = mean(xdata(:));
this_msg = horzcat('avg. similarity = ', num2str(avg_sim));
disp(this_msg)
tx2.String = horzcat(this_msg);
drawnow


%% Plot similarity matrix

axes(im_ax1)
imagesc(xdata, [0 0.5])
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

