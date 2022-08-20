


state_entropy = zeros(n_unique_states, 1);
sort_inds = [];
for nstate = 1:n_unique_states
    these_inds = find(group_inds == nstate);
    sort_inds = [sort_inds these_inds];
    these_corrs = corr(xdata(these_inds,these_inds));
    state_entropy = mean(these_corrs(:));
end
figure(5)
histogram(state_entropy)
title('State entropies')