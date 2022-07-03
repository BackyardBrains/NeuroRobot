
images_dir = dir(fullfile(rootdir, '**\*.png'));  %get list of files and folders in any subfolder
nimages = size(images_dir,1);
disp(horzcat('nstates: ', num2str(nstates)))

states = zeros(nimages/2, 1);

for nstep = 1:nimages/2

    if ~rem(nstep, round((nimages/2)/100))
        disp(num2str(nstep/(nimages/2)))
    end

    left_state = NaN;
    right_state = NaN;
    this_state = NaN;

    for ii = 1:2
        
        this_ind = nstep*2-(ii-1);
        
        this_im = imread(strcat(images_dir(this_ind).folder, '\',  images_dir(this_ind).name));
        this_im = imresize(this_im, 'outputsize', [50 50]);
        state = classify(net, this_im);
        
        if ii == 1
            left_state = find(unique_states == state);
        elseif ii == 2
            right_state = find(unique_states == state);
        end
        
    end

    if left_state == right_state
        this_state = left_state;
    elseif ~isnan(left_state)
        this_state = left_state;
    elseif ~isnan(right_state)
        this_state = right_state;
    end

    states(nstep, 1) = this_state;

end

save(horzcat(rootdir, 'states.mat'), 'states')
