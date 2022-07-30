
clear
clc

tuples_dir_name = 'C:\Users\Christopher Harris\RandomWalkData\Rec_1\';
image_ds = imageDatastore(tuples_dir_name, 'FileExtensions', '.png', 'IncludeSubfolders', true);
imageIndex = indexImages(image_ds);
imageIndex.MatchThreshold = 0;

%%
nframes = length(imageIndex.ImageLocation);
xdata = zeros(nframes, nframes);
for ii = 1:nframes
    disp(horzcat('Processing image ', num2str(ii), ' of ', num2str(nframes)))
    img = readimage(image_ds, ii);
    [inds,scores] = retrieveImages(img, imageIndex, 'NumResults', Inf);
    xdata(ii, inds) = scores;
end

%%
nclusters1 = 10;
inds = kmeans(xdata, nclusters1);
ydata = zeros(nclusters1, nframes);
for ii = 1:nclusters1
    ydata(ii, :) = mean(xdata(inds == ii, :));
    yinds{ii} = find(inds == ii);
end

figure(1)
clf
histogram(inds, 'binwidth', 1)

%%
noise_cluster = mode(inds);
noise_inds = yinds{noise_cluster};
for ii = 1:length(noise_inds)
    this_array = xdata(:, noise_inds(ii));
    temp = zeros(nclusters1, 1);
    for jj = 1:nclusters1
        temp(jj) = immse(this_array, ydata(jj ,:)');
    end
    [i, j] = sort(temp);
    inds(noise_inds(ii)) = j(2);
end

figure(2)
clf
histogram(inds, 'binwidth', 1)

%%
for ii = 1:nclusters1
    figure(10+ii)
    clf
    x = find(inds == ii);
    if length(x) > 20
        x = randsample(x, 20);
    end
    montage(imageIndex.ImageLocation(x))
end

%%
inds = dbscan(xdata, 0.25, 5);
unique_inds = unique(inds);
unique_inds(unique_inds == -1) = [];
nclusters1 = length(unique_inds);
disp(horzcat('nclusters: ', num2str(nclusters1)))

ydata = zeros(nclusters1, nframes);
for ii = 1:nclusters1
    ydata(ii, :) = mean(xdata(inds == ii, :));
    yinds{ii} = find(inds == ii);
end

figure(3)
clf
subplot(1,2,1)
histogram(inds, 'binwidth', 1)

noise_inds = find(inds == -1);
for ii = 1:length(noise_inds)
    this_array = xdata(:, noise_inds(ii));
    temp = zeros(nclusters1, 1);
    for jj = 1:nclusters1
        temp(jj) = immse(this_array, ydata(jj ,:)');
    end
    [i, j] = sort(temp);
    inds(noise_inds(ii)) = j(2);
end

noise_inds = find(inds == mode(inds));
for ii = 1:length(noise_inds)
    this_array = xdata(:, noise_inds(ii));
    temp = zeros(nclusters1, 1);
    for jj = 1:nclusters1
        temp(jj) = immse(this_array, ydata(jj ,:)');
    end
    [i, j] = sort(temp);
    this_ind = randsample(2:round(nclusters1/2), 1);
    inds(noise_inds(ii)) = j(this_ind);
end

subplot(1,2,2)
histogram(inds, 'binwidth', 1)

%%
for ii = 1:nclusters1
    figure(10+ii)
    clf
    x = find(inds == ii);
    if length(x) > 20
        x = randsample(x, 20);
    end
    montage(imageIndex.ImageLocation(x))
    title(horzcat('Group ', num2str(ii)))
end