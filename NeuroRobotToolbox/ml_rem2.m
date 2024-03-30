

data2 = [];
for init_n_unique_states = 500:200:3000
    for min_size = 30:10:80

        ml_get_clusters
        sdata = zeros(n_unique_states, 1);
        for nstate = 1:n_unique_states
            these_inds = state_inds(nstate, :);
            these_scores = mean(xdata(these_inds,these_inds), 2);
            sdata(nstate) = mean(these_scores);
        end
        central_mean = mean(sdata);
        data2 = [data2; init_n_unique_states min_size n_unique_states central_mean]

    end
end


