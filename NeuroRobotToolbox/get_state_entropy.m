


state_entropy = zeros(n_unique_states, 1);
sort_inds = [];
for nstate = 1:n_unique_states
    these_inds = find(group_inds == nstate);
    sort_inds = [sort_inds; these_inds];
    these_corrs = corr(xdata(these_inds,these_inds));
    state_entropy(nstate) = mean(these_corrs(:));
end
figure(5)
clf
histogram(state_entropy, 'binwidth', 0.001)
hold on
plot([median(state_entropy) median(state_entropy)], [0 2] + 2, 'linewidth', 2, 'color', 'r')
title('State entropies')
1