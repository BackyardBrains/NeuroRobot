function this_im = customReadFcn(im_fname)

    this_im = imread(im_fname);
%     this_im = imresize(this_im, [227 227]);    
%     this_im = imresize(this_im, [227 404]);
    this_im = imresize(this_im, [100 178]);

end