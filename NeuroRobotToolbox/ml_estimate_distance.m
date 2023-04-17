

im1 = imread('C:\Users\chris\OneDrive\Documents\MATLAB\Workspace\livingroommini\s23-tv01\im6171.png');
im2 = imread('C:\Users\chris\OneDrive\Documents\MATLAB\Workspace\livingroommini\s23-tv01\im397.png');

im1 = rgb2gray(im1);
im2 = rgb2gray(im2);

pts1 = detectSURFFeatures(im1);
pts2 = detectSURFFeatures(im2);

[fts1, valpts1] = extractFeatures(im1, pts1);
[fts2, valpts2] = extractFeatures(im2, pts2);

index_pairs = matchFeatures(fts1, fts2);

mpts1  = valpts1(index_pairs(:,1));
mpts2 = valpts2(index_pairs(:,2));

figure(1)
clf
showMatchedFeatures(im1, im2, mpts1 , mpts2)
title("Matched SURF Points With Outliers")

[tform,inlierIdx] = estgeotform3d(mpts2, mpts1, "similarity");
ipts2 = mpts2(inlierIdx,:);
ipts1 = mpts1(inlierIdx,:);

figure(2)
clf
showMatchedFeatures(im1, im2, ipts1, ipts2)
title("Matched Inlier Points")

