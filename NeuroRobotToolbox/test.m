
figure(2)
subplot(2,2,1)
im1 = rgb2gray(left_im)
im2 = rgb2gray(right_im)
image(im1)
subplot(2,2,2)
image(im2)
c = normxcorr2(im1, im2)
[ypeak,xpeak] = find(c==max(c(:)));

