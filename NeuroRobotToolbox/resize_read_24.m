function data = resize_read_24(filename)

    data = imread(filename);
    data = imresize(data,[24 32]);

end