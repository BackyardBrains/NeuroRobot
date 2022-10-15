
imdim = 100;
states = zeros(ntuples, 1);
disp(horzcat('Getting ', num2str(ntuples), ' states from camera frames (slow, be patient...)'))
confusion = zeros(ntuples, 2);
for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(horzcat('Counter: ', num2str(round(100*(ntuple/ntuples))), '%, ntuple: ', num2str(ntuple)))
    end

    left_state = NaN;
    right_state = NaN;
    this_state = NaN;

    this_ind = ntuple*2-1;    
    left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    left_im = imresize(left_im, [imdim imdim]);

    this_ind = ntuple*2;
            
    right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    right_im = imresize(right_im, [imdim imdim]);

    [left_state, left_score] = classify(net, left_im);
    [right_state, right_score] = classify(net, right_im);        
        
    left_state = find(unique_states == left_state);
    right_state = find(unique_states == right_state);

    left_score = left_score(left_state);
    right_score = right_score(right_state);

    if ~isempty(left_score) && ~isempty(right_score)
    confusion(ntuple, :) = [left_score right_score];
%     if max([left_score right_score]) > 0.9
        if left_state == right_state
            this_state = left_state;
        elseif left_score >= right_score
            this_state = left_state;
        else
            this_state = right_state;
        end
%     else
%         this_state = nan;
%         confusions = confusions + 1;
%     end
    else
        this_state = 1;
        disp('error')
    end
    states(ntuple) = this_state;

end

