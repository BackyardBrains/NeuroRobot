
fig_mdp = figure(5);
clf
set(fig_mdp, 'NumberTitle', 'off', 'Name', 'MDP')
set(fig_mdp, 'toolbar', 'none')

set(fig_mdp, 'position', [360 70 800 720], 'color', fig_bg_col) 
fig_mdp.Color = 'w';

data = zeros(n_unique_actions, 1);
x = ceil(sqrt(n_unique_actions));

for naction = 1:n_unique_actions

    motor_out = round(mean(torque_data(actions == naction, :), 1));
    
    subplot(x, x, naction)
    imagesc(mean(mdp.T(:,:,naction), 3), [0 1])
    title(horzcat('Action: ', num2str(naction), '.  L: ', num2str(motor_out(1)), ',  R: ', num2str(motor_out(2))))
    ylabel('State')
    xlabel('Next State')
end

