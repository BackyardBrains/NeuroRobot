legal_transitions = nan(nsteps - 1, 1);
for nstep = 1:nsteps-1
    good_shift = 0;
    this_state = states(nstep);
    this_next_state = states(nstep+1);
    if ~isnan(this_state) && ~isnan(this_next_state)
        this_loc = xdata(this_state, 1:2);
        this_next_loc = xdata(this_next_state, 1:2);
        xy_shift = abs(this_loc - this_next_loc);
        if xy_shift(1) <= 1 && xy_shift(2) <= 1
            good_shift = 1;
        end
    end
    legal_transitions(nstep) = good_shift;
end


