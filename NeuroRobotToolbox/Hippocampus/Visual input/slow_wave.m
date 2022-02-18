
ims = imageDatastore(pwd);
bag = bagOfFeatures(ims);
frames = readall(ims);

%%
nframes = length(frames);
nfeatures = bag.NumVisualWords;
xdata = zeros(nframes, nfeatures);
for nframe = 1:nframes
    img = frames{nframe};
    featureVector = encode(bag,img);
    xdata(nframe, :) = featureVector;
end

%%
dists = pdist(xdata);
links = linkage(dists, 'average');
figure(3)
clf
[~, ~, o] = dendrogram(links, nframes);

%%
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

%%
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


%%
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



