


clear
clc

tuples_dir_name = 'C:\Users\Christopher Harris\RandomWalkData\';
image_ds = imageDatastore(tuples_dir_name, 'FileExtensions', '.png', 'IncludeSubfolders', true);
imageIndex = indexImages(image_ds);
imageIndex.MatchThreshold = 0;

test_ind = 234;
img = readimage(image_ds, test_ind);
[inds,scores] = retrieveImages(img, imageIndex, 'NumResults', 10);

nframes = length(imageIndex.ImageLocation);
xdata = zeros(nframes, nframes);
for ii = 1:nframes
    disp(horzcat('Processing image ', num2str(ii), ' of ', num2str(nframes)))
    img = readimage(image_ds, test_ind);
    uframe = memory_images{ii};
    [inds,scores] = retrieveImages(uframe,imageIndex,'NumResults',Inf);
    xdata(ii, inds) = scores;
end

pdist
T2 = clusterdata(X,'Maxclust',3); 

n_unique_actions = 10;
[states, cstates] = kmeans(torque_data, n_unique_actions);
save('actions2', 'actions')
save('cactions', 'cactions')
load('actions2')
load('cactions')
n_unique_actions = length(unique(actions));


% n_unique_states


