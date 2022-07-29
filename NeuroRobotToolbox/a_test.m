


clear
clc

tuples_dir_name = 'C:\Users\Christopher Harris\RandomWalkData\';
image_ds = imageDatastore(tuples_dir_name, 'FileExtensions', '.png', 'IncludeSubfolders', true);
imageIndex = indexImages(image_ds);
imageIndex.MatchThreshold = 0;

% [IDs,scores] = retrieveImages(uframe,imageIndex,'NumResults',20);
% n_unique_states


