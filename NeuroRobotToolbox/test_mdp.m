

origin = [2 1 3 4 2] - 1;

figure(11)
clf

data = [];
for ii = 1:4:n_unique_states
    for jj = 1:4
        this_state = ii + origin(jj);
        this_next_state = ii + origin(jj + 1);
        this_array = squeeze(mdp.T(this_state, this_next_state, :));
        data = [data this_array];
    end
end

plot(mean(data, 2), 'color', [0.8 0.4 0.2])

data = [];
for ii = 1:4:n_unique_states
    for jj = 1:4
        this_state = ii + origin(jj + 1);
        this_next_state = ii + origin(jj);
        this_array = squeeze(mdp.T(this_state, this_next_state, :));
        data = [data this_array];
    end
end

hold on
plot(mean(data, 2), 'color', [0.2 0.4 0.8])
