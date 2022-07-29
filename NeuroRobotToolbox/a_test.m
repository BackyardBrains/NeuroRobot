


clear
clc

% tuples_dir_name = 'C:\Users\Christopher Harris\RandomWalkData\';
tuples_dir_name = 'C:\Users\Christopher Harris\Rec_1\';
image_ds = imageDatastore(tuples_dir_name, 'FileExtensions', '.png', 'IncludeSubfolders', true);
imageIndex = indexImages(image_ds);
imageIndex.MatchThreshold = 0;

% test_ind = 900;
% img = readimage(image_ds, test_ind);
% [inds,scores] = retrieveImages(img, imageIndex, 'NumResults', 10);

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
n_unique_states = 100;
[states, cstates] = kmeans(xdata, n_unique_states);
figure(1)
clf
histogram(states, 'binwidth', 1)

for ii = 1:n_unique_states
    figure(10+ii)
    clf
    x = find(states == ii);
    if length(x) > 20
        x = randsample(x, 20);
    end
    montage(imageIndex.ImageLocation(x))
end

