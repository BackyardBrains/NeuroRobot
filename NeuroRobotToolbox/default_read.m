function data = default_read(filename)

    data = imread(filename);
    data = imresize(data,[240 320]);

end