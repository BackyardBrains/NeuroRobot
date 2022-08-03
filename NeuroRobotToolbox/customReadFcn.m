function this_im = customReadFcn(im_fname)

    imdim = 100;

    this_im = imread(im_fname);
%     this_im = rgb2gray(this_im);
    this_im = imresize(this_im, [imdim imdim]);

end