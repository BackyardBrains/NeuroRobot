
imdim = 100;
ims = zeros(100, 178, 1, ntuples);
disp(horzcat('getting ', num2str(ntuples), ' images'))

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end

    this_ind = ntuple*2-1;    
    left_im_link = strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name);
    left_im = imread(left_im_link);
    left_im = imresize(left_im, [imdim imdim]);
    left_im = rgb2gray(left_im);
    
    this_ind = ntuple*2;
    right_im_link = strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name);
    right_im = imread(right_im_link);
    right_im = imresize(right_im, [imdim imdim]);
    right_im = rgb2gray(right_im);

    ims(:,1:100,:,ntuple) = left_im;
    ims(:,79:178,:,ntuple) = right_im;

end
