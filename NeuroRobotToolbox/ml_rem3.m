

a = mean(mdp.T(:,:,[5,7]), 3) - mean(mdp.T(:,:,[4,9]), 3);
b = 1;
x = 1;

for ii = 1:n_unique_states

    [~, j] = sort(a(x,:), 'ascend');
    if j(1) ~= x
        x = j(1);
    else
        x = j(2);
    end
    b = [b x];

end
b

