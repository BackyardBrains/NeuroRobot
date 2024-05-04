function data = resize_read_48(filename)

    data = imread(filename);
    data = imresize(data,[48 64]);

end