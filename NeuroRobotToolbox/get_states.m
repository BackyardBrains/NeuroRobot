
imdim = 227;
states = zeros(ntuples, 1);
disp(horzcat('Getting ', num2str(ntuples), ' states from camera frames (slow, be patient...)'))
confusion = zeros(ntuples, 2);
new_im = zeros(227, 404, 3, 'uint8');
for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/100))
        disp(horzcat('Counter: ', num2str(round(100*(ntuple/ntuples))), '%, ntuple: ', num2str(ntuple)))
    end

    this_ind = ntuple*2-1;    
    left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    left_im = imresize(left_im, [imdim imdim]);

    this_ind = ntuple*2;
    right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    right_im = imresize(right_im, [imdim imdim]);

    new_im(:, 1:227, :) = left_im;
    new_im(:, 178:404, :) = right_im;
    [state, scores] = classify(net, new_im);
    this_state = find(unique_states == state);
    score = scores(this_state); % mislabeled and unused?

    states(ntuple) = this_state;

end

