

%% Get inter-state similarity

axes(ax4)
cla
tx4 = text(0.03, 0.5, horzcat('getting inter-state similarities...'));
drawnow

inter_state_similarity = zeros(n_unique_states, n_unique_states);
for nstate = 1:n_unique_states
    these_inds = state_inds(nstate, :);

    for nstate2 = 1:n_unique_states
        these_inds2 = state_inds(nstate2, :);
        vals = xdata(these_inds,these_inds2);
        vals(vals == 1) = nan;
        inter_state_similarity(nstate, nstate2) = mean(vals(:), 'omitnan');
    end

end

axes(im_ax1)
cla
imagesc(inter_state_similarity)
xlabel('State')
ylabel('State')
c = colorbar('location', 'manual', 'position', im_ax1_colb_pos);
title('Inter-state similarity')

avg_inter = mean(inter_state_similarity(:));
tx4.String = horzcat('avg. inter-state = ', num2str(avg_inter), ', getting intra-state...');
drawnow


%% Get intra-state similarity
intra_state_similarity = zeros(n_unique_states, 1);
for nstate = 1:n_unique_states
    these_inds = state_inds(nstate, :);

    vals = xdata(these_inds,these_inds);
    vals(vals == 1) = nan;
    intra_state_similarity(nstate) = mean(vals(:), 'omitnan');

end

prc25 = prctile(intra_state_similarity, 25);

axes(im_ax2)
cla
bar(intra_state_similarity)
xlabel('State')
ylabel('Score')
title('Intra-state similarity')

% axes(im_ax2)
% cla
% h = histogram(intra_state_similarity, 'binwidth', 0.005);
% hold on
% plot([prc25 prc25], [0 max(h.Values)], 'linewidth', 2, 'color', 'r')
% title('Intra-state similarity (histogram)')

avg_intra = mean(intra_state_similarity);
tx4.String = horzcat('avg. inter-state = ', num2str(avg_inter), ...
    ', avg. intra-state = ', num2str(avg_intra));
drawnow


