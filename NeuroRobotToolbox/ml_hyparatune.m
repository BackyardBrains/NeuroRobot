
%%
nims = [200 400 600 800 1000];
data = struct;
for ncycle = 1:5
    init_n_unique_states = nims(ncycle);
    min_size = 40;
	ml_get_clusters
 	ml_quality
    n_selected_states = 0;
    for nstate = 1:n_unique_states
        if intra_state_similarity(nstate) > 0.2 && intra_state_similarity(nstate) < 0.95
            n_selected_states = n_selected_states + 1;
            these_inds = state_inds(nstate, :);
            data(ncycle).state(n_selected_states).inds = these_inds;
        end
    end
    disp(horzcat('cycle: ', num2str(ncycle), ', selected states: ', num2str(n_selected_states)))    
end


%%
ncycles = 5;
n_unique_states = 0;
for ncycle = 1:ncycles
    n_unique_states = n_unique_states + length(data(ncycle).state);
end
disp(num2str(n_unique_states))

state_inds = zeros(n_unique_states, min_size);
s = 0;
for ncycle = 1:ncycles
    nstates = length(data(ncycle).state);
    for nstate = 1:nstates
        s = s + 1;
        state_inds(s, :) = data(ncycle).state(nstate).inds;
    end
end


%%
inter_state_similarity = zeros(nstates, nstates);
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

figure(2)
clf
imagesc(inter_state_similarity)


%%
% %%
% 
% data = zeros(5, 5, 5);
% bfsize = 4;
% c1 = 0;
% for init_n_unique_states = 200:400:2000
%     c1 = c1 + 1;
%     c2 = 0;
%     for min_size = 20:20:100
%         c2 = c2 + 1;
%         % ml_get_data_stats
%         % ml_get_similarity
%         ml_get_clusters
%         ml_quality
%         % ml_finalize_training_data
%         vals = [init_n_unique_states, min_size, n_unique_states, avg_intra, avg_inter]
%         data(c1, c2, :) = vals;
%         disp(horzcat('c2: ', num2str(c2)))
%     end
%     disp(horzcat('c1: ', num2str(c1)))
% end
