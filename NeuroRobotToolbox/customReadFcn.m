function this_im = customReadFcn(im_fname)

    this_im = imread(im_fname);
    this_im = imresize(this_im, [227 404]);

end