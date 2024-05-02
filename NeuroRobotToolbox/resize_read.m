function data = resize_read(filename)

    data = imread(filename);
    data = imresize(data,[48 64]);

end