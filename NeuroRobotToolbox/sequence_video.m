

these_tuples = this_start_ind : this_start_ind + this_many_steps + 10;

counter = length(these_tuples) - 10;
disp(horzcat('steps = ', num2str(counter)))

for ntuple = these_tuples

    counter = counter - 1;

    this_ind = ntuple*2-1;    
    left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    left_im = imresize(left_im, [imdim imdim]);

    this_ind = ntuple*2;        
    right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    right_im = imresize(right_im, [imdim imdim]);

    montage({left_im right_im})
    title(horzcat('current state = ', num2str(states(ntuple)), ', remaining steps = ', num2str(counter)))
    writeVideo(vid_writer, getframe(10));
    drawnow

    pause(0.1)
   
end
 
