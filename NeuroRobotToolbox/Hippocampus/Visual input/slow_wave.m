
%% Create image datastore (run in png directory)
ims = imageDatastore(pwd);
frames = readall(ims);

%% Create Bag of Features
bag = bagOfFeatures(ims);

%% Get feature vectors
nframes = length(frames);
nfeatures = bag.NumVisualWords;
xdata = zeros(nframes, nfeatures);
for nframe = 1:nframes
    img = frames{nframe};
    [featureVector, words] = encode(bag, img); % check what's in words, also check if can paralellize
    xdata(nframe, :) = featureVector;
end

%% Get distances
dists = pdist(xdata);
links = linkage(dists, 'average');
figure(3)
clf
[~, ~, o] = dendrogram(links, nframes);

%% K-means clustering
ngroups = 10;
inds = kmeans(links, ngroups);
for ii = 1:ngroups
    figure(3+ii)
    clf
    x = find(inds == ii);
    if length(x) > 20
        x = randsample(x, 20);
    end
    montage({frames{x}})
end

%% Hierarchical clustering
ngroups = 10;
clusts = cluster(links,'maxclust',ngroups);
for ii = 1:ngroups
    figure(3+ii)
    clf
    x = find(clusts == ii);
    if length(x) > 20
        x = randsample(x, 20);
    end
    montage({frames{x}})
end

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



