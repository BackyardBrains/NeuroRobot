

states = zeros(ntuples, 1);

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end

    left_state = NaN;
    right_state = NaN;
    this_state = NaN;

    for ii = 1:2
        
        this_ind = ntuple*2-(ii-1);
        
        this_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
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

    states(ntuple) = this_state;

end

save('states', 'states')

