
im3 = flipud(255 - ((255 - imread('workspace2.jpg'))));
im = mean(im3, 3);
im = im > 200;
cc = bwconncomp(im);
numPixels = cellfun(@numel,cc.PixelIdxList);
[biggest,idx] = max(numPixels);

figure(1)
clf
imagesc(im)
set(gca, 'ydir', 'normal')

[y, x] = ind2sub([1283 1283], cc.PixelIdxList{idx});