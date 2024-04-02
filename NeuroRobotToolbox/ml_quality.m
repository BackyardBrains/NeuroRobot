

%% Get inter-state similarity
try
axes(ml_train1_status)
cla
catch
end

inter_state_similarity = zeros(n_unique_states, n_unique_states);
for nstate = 1:n_unique_states
    these_inds = state_inds(nstate, :);

    for nstate2 = 1:n_unique_states
        these_inds2 = state_inds(nstate2, :);
        if nstate ~= nstate2
            vals = xdata(these_inds,these_inds2);
    %         vals(vals == 1) = nan;
            inter_state_similarity(nstate, nstate2) = mean(vals(:), 'omitnan');
        end
    end

end

avg_inter = mean(inter_state_similarity(:));


%% Get intra-state similarity
intra_state_similarity = zeros(n_unique_states, 1);
for nstate = 1:n_unique_states
    these_inds = state_inds(nstate, :);

    vals = xdata(these_inds,these_inds);
%     vals(vals == 1) = nan;
    intra_state_similarity(nstate) = mean(vals(:), 'omitnan');

end

avg_intra = mean(intra_state_similarity);

try
this_msg = horzcat('Similarity: between groups = ', num2str(avg_inter), ', within groups = ', num2str(avg_intra));
tx4.String = this_msg;
drawnow
catch
end
