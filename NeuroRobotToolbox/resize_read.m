function data = resize_read(filename)

    data = imread(filename);
    data = imresize(data,[24 32]);

end