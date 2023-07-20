

[i, j] = sort(thetas, 'descend')

figure(2)
clf
subplot(2,2,1)
l_im = image(zeros(227,227,3,'uint8'));
l_tx = title('');
subplot(2,2,2)
r_im = image(zeros(227,227,3,'uint8'));
r_tx = title('');

for ntuple = 1:ntuples

    this_ind = j(ntuple);

    this_im_ind = this_ind * 2 - 1;    
    left_im = imread(strcat(image_dir(this_im_ind).folder, '\',  image_dir(this_im_ind).name));
    l_im.CData = left_im;
    l_tx.String = num2str(thetas(this_ind));
    this_im_ind = this_ind * 2;
    right_im = imread(strcat(image_dir(this_im_ind).folder, '\',  image_dir(this_im_ind).name));
    r_im.CData = right_im;
    r_tx.String = num2str(thetas(this_ind));
    disp(horzcat('ntuple = ', num2str(ntuple), ', thetas = ', num2str(thetas(this_ind))))
    drawnow
    
end



