
origin = [2 1 3 4 2] - 1;
turning_left = [];
for ii = 1:4:n_unique_states
    for jj = 1:4
        this_array = squeeze(mdp.T(ii + origin(jj), ii + origin(jj + 1), :))
        turning_left = [turning_left this_array];
    end
end

figure(1)
clf
plot(mean(turning_left, 2))
