function data = resize_read_120(filename)

    data = imread(filename);
    data = imresize(data,[120 180]);

end