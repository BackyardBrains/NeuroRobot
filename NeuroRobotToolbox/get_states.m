
states = zeros(ntuples, 1);
disp(horzcat('Getting ', num2str(ntuples), ' states from camera frames (slow)'))

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/100))
        disp(horzcat('Counter: ', num2str(round(100*(ntuple/ntuples))), '%, ntuple: ', num2str(ntuple)))
    end

    left_state = NaN;
    right_state = NaN;
    this_state = NaN;

    this_ind = ntuple*2-1;    
    left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));

    this_ind = ntuple*2;
    right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));

    [left_state, left_score] = classify(net, left_im);
    [right_state, right_score] = classify(net, right_im);        
        
    left_state = find(labels == left_state);
    right_state = find(labels == right_state);

    left_score = left_score(left_state);
    right_score = right_score(right_state);

    if ~isempty(left_score) && ~isempty(right_score)
        if left_state == right_state
            this_state = left_state;
        elseif left_score >= right_score
            this_state = left_state;
        else
            this_state = right_state;
        end
    else
        this_state = nan;
        disp('error')
    end
    states(ntuple) = this_state;

end
