

%% Create image datastore (run in png directory)
ims = imageDatastore('.\Experiences\*.png');
nfiles = length(ims.Files);
ims = subset(ims, randsample(nfiles, round(nfiles/2)));
frames = readall(ims);
nframes = length(frames);

%% Create Bag of Features
bag = bagOfFeatures(ims, 'TreeProperties', [1 5]);
save('bag.mat', 'bag')
nfeatures = bag.NumVisualWords;

%% Get feature vectors
xdata = zeros(nframes, nfeatures);
for nframe = 1:nframes
    img = frames{nframe};
    [featureVector, words] = encode(bag, img);
    xdata(nframe, :) = featureVector;
end

%% Get distances
dists = pdist(xdata);
links = linkage(dists, 'average');
figure(11)
clf
[~, ~, o] = dendrogram(links, nframes);

%% K-means clustering
ngroups = 100;
inds = kmeans(links, ngroups);
for ii = 1:ngroups
    figure(3)
    clf
    montage({frames{inds == ii}})
end
histogram(inds, 'binwidth', 1)

%% Hierarchical clustering
ngroups = 10;
clusts = cluster(links,'maxclust',ngroups);
% clusts = cluster(links,'cutoff',1.154698);
for ii = 1:ngroups
    figure(ii)
    clf
    montage({frames{clusts == ii}})
    title(horzcat('Group ', num2str(ii)))
end
figure(ii+1)
histogram(clusts, 'binwidth', 1)

% %% dbscan clustering
% y = dbscan(xdata, 0.8, 5);
% z = unique(y);
% z(z == -1) = [];
% ngroups = length(z);
% for ii = 1:ngroups
%     figure(3+ii)
%     clf
%     x = find(y == ii);
%     if length(x) > 20
%         x = randsample(x, 20);
%     end    
%     montage({frames{x}})
%     title(horzcat('Group ', num2str(ii)))
% end



