

fig_ml = figure(4);
clf
set(fig_ml, 'NumberTitle', 'off', 'Name', 'States')
set(fig_ml, 'toolbar', 'none')
set(fig_ml, 'position', [175 70 1200 720], 'color', 'w') 

x = ceil(sqrt(n_unique_states));

for ii = 1:1
    
    ii;

    for nstate = 1:n_unique_states
        subplot(x, x, nstate)
        rand_inds = randsample(n_images_per_state, nexamples);
        this_ds = subset(image_ds, ((nstate - 1) * n_images_per_state) + rand_inds);
        montage(this_ds)
        set(gca, 'xtick', [], 'ytick', [])
        title(horzcat('state: ', num2str(nstate), ', s: ', num2str(0)))
    end

    title(state_net_name)
    drawnow

end

