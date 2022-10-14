function this_im = customReadFcn(im_fname)

    imdim = 100;
    this_im = imread(im_fname);
    this_im = imresize(this_im, [imdim imdim]);

end