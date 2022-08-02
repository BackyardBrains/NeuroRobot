

states = zeros(ntuples, 1);
disp(horzcat('getting ', num2str(ntuples), ' states from camera frames'))
confusions = 0;
for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/100))
        disp(horzcat('Counter: ', num2str(ntuple/ntuples), ...
            ', ntuple: ', num2str(ntuple), ...
            ', confusions: ', num2str(confusions)))
        confusions = 0;
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
        
    left_state = find(unique_states == left_state);
    right_state = find(unique_states == right_state);

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
    
    states(ntuple) = this_state;

end

