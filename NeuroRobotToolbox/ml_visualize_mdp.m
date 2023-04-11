
fig_ml = figure(5);
clf
set(fig_ml, 'NumberTitle', 'off', 'Name', 'Visualize MDP')
set(fig_ml, 'menubar', 'none', 'toolbar', 'none')

fig_pos = get(0, 'screensize') + [0 49 0 -71];
set(fig_ml, 'position', fig_pos, 'color', fig_bg_col) 

data = zeros(n_unique_actions, 1);
x = factor(n_unique_actions);
for naction = 1:n_unique_actions

    motor_out = round(mean(torque_data(actions == naction, :), 1));
    
    subplot(x(1), x(2), naction)
    imagesc(mean(mdp.T(:,:,naction), 3), [0 1])
    title(horzcat('Action: ', num2str(naction), '.  L: ', num2str(motor_out(1)), ',  R: ', num2str(motor_out(2))))
    ylabel('State')
    xlabel('Next State')
end

