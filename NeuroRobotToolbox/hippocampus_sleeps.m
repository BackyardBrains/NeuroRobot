

tic

%% Create image datastore (run in png directory)
ims = imageDatastore('.\Experiences\*.png');
n = length(ims.Files);
ims = subset(ims, randsample(n, round(n/1)));
frames = readall(ims);
nframes = length(frames);
% % imageIndex = indexImages(ims);

%% Create Bag of Features
bag = bagOfFeatures(ims, 'TreeProperties', [1 5]);
save('bag_raw1.mat', 'bag')
nfeatures = bag.NumVisualWords;
disp(horzcat('Hippocampus slept ', num2str(round(toc/60/60)), ' hrs'))

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

%% Clustering
ngroups = 200;
clusts = cluster(links,'maxclust',ngroups);
for ii = 1:ngroups
    if sum(clusts == ii) > 20
        figure(ii)
        clf
        montage({frames{clusts == ii}})
        title(horzcat('Group ', num2str(ii)))
    end
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



