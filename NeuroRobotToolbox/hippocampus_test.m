
% clear
% clc
% 
% imdim = 100;
% data_dir_name = 'C:\Users\Christopher Harris\Dataset 1\';
% rec_dir_name = 'Classifier\';
% 
% image_ds = imageDatastore(strcat(data_dir_name, rec_dir_name), ...
%     'FileExtensions', '.png', 'IncludeSubfolders', 1, 'LabelSource','foldernames');
% image_ds.ReadFcn = @customReadFcn;
% nimages = length(image_ds.Files);
% 
% bag = bagOfFeatures(image_ds, 'treeproperties', [2 200]);
% % save(strcat(data_dir_name, 'bag'), 'bag')
% imageIndex = indexImages(image_ds, bag);
% 
% labels = unique(image_ds.Labels);
% ngroups = length(labels);

queryROI = [1, 1, imdim - 1, imdim - 1];
xdata = zeros(nimages, nimages);
for ngroup = 1:ngroups
    disp(horzcat('Processing group ', num2str(ngroup)))
    inds = find(image_ds.Labels == labels(ngroup));
    for ind = inds'
        img = readimage(image_ds, ind);
        [xinds, similarity_scores] = retrieveImages(img, imageIndex, 'Metric', 'L1', 'ROI', queryROI, 'NumResults', Inf);
        xdata(ind, xinds) = similarity_scores;
    end
end

