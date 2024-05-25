
fig_mdp = figure(14);
clf
set(fig_mdp, 'NumberTitle', 'off', 'Name', 'MDP')
set(fig_mdp, 'toolbar', 'none')

set(fig_mdp, 'position', [262 62 828 732], 'color', 'w') 
fig_mdp.Color = 'w';

% data = zeros(n_unique_actions, 1);
x = ceil(sqrt(length(main_actions)));

counter = 0;
for naction = main_actions

    counter = counter + 1;

    motor_out = round(mean(torque_data(actions == naction, :), 1));
    
    subplot(x, x, counter)
    imagesc(mdp.T(:,:,naction), [0 0.5])
    title(horzcat('Action: ', num2str(naction), '.  L: ', num2str(motor_out(1)), ',  R: ', num2str(motor_out(2))))
    ylabel('State')
    xlabel('Next State')
end

