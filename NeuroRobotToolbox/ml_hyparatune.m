

data = zeros(5, 5, 5);
bfsize = 4;
c1 = 0;

for init_n_unique_states = 200:400:2000
    c1 = c1 + 1;
    c2 = 0;
    for min_size = 20:20:100
        c2 = c2 + 1;

        % ml_get_data_stats
        % ml_get_similarity
        ml_get_clusters
        ml_quality
        % ml_finalize_training_data

        vals = [init_n_unique_states, min_size, n_unique_states, avg_intra, avg_inter]
        data(c1, c2, :) = vals;

        disp(horzcat('c2: ', num2str(c2)))
    end
    disp(horzcat('c1: ', num2str(c1)))
end


%%
figure(6)
clf

