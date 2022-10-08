

figure(1)
clf
subplot(1,2,1)
im1 = image(zeros(227, 227, 3));
t1 = title('1');
subplot(1,2,2)
im2 = image(zeros(227, 227, 3));
t2 = title('2');

for nimage = 1:nimages

    similarity_scores = xdata(nimage, :);
    [score, inds] = sort(similarity_scores, 'descend');
    
    this_im = imread(imageIndex.ImageLocation{nimage});
    im1.CData = this_im;
    t1.String = horzcat('Image ', num2str(nimage));

    this_im = imread(imageIndex.ImageLocation{inds(2)});
    im2.CData = this_im;
    t2.String = horzcat('Image ', num2str(inds(2)), ', score: ', num2str(score(2)), ')');

    pause
end

