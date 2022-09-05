

these_tuples = this_start_ind : this_start_ind + this_many_steps;

counter = length(these_tuples);
for ntuple = these_tuples

    counter = counter - 1;

    this_ind = ntuple*2-1;    
    left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    left_im = imresize(left_im, [imdim imdim]);

    this_ind = ntuple*2;        
    right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    right_im = imresize(right_im, [imdim imdim]);

    montage({left_im right_im})

    drawnow

    if ntuple == these_tuples(end)
        title('goal state reached')
        for ii = 1:10
            writeVideo(vid_writer, getframe(10));
        end
    else
        title(horzcat('start state = ', num2str(states(ntuple)), ', steps remaining = ', num2str(counter)))
        writeVideo(vid_writer, getframe(10));
    end
    
end


 
