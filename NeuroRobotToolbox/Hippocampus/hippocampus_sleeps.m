
%% Create image datastore (run in png directory)
ims = imageDatastore(pwd);
frames = readall(ims);
nframes = length(frames);

%% Create Bag of Features
bag = bagOfFeatures(ims);
nfeatures = bag.NumVisualWords;

%% Get feature vectors
xdata = zeros(nframes, nfeatures);
for nframe = 1:nframes
    img = frames{nframe};
    [featureVector, words] = encode(bag, img); % check what's in words, also check if can paralellize
    xdata(nframe, :) = featureVector;
end

%% Get distances
dists = pdist(xdata);
links = linkage(dists, 'average');
figure(11)
clf
[~, ~, o] = dendrogram(links, nframes);
% xdata_o = zeros(nframes, nfeatures);
% for ii = 1:500
%     xdata_o(:,ii) = xdata(o,ii);
% end
% dists_o = pdist(xdata_o);
% links_o = linkage(dists_o, 'average');
% figure(12)
% clf
% [~, ~, o] = dendrogram(links_o, nframes);


%% K-means clustering
ngroups = 10;
inds = kmeans(links, ngroups);
for ii = 1:ngroups
    figure(3)
    clf
    montage({frames{inds == ii}})
end

%% Hierarchical clustering
ngroups = 20;
clusts = cluster(links,'maxclust',ngroups);
% clusts = cluster(links,'cutoff',0.5);
for ii = 1:ngroups
    figure(ii)
    clf
    montage({frames{clusts == ii}})
end
figure(ii+1)
histogram(clusts)

%% dbscan clustering
y = dbscan(xdata, 0.8, 5);
z = unique(y);
z(z == -1) = [];
ngroups = length(z);
for ii = 1:ngroups
    figure(3+ii)
    clf
    x = find(y == ii);
    if length(x) > 20
        x = randsample(x, 20);
    end    
    montage({frames{x}})
    title(horzcat('Group ', num2str(ii)))
end



