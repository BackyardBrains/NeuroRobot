
fig_mdp = figure(14);
clf
set(fig_mdp, 'NumberTitle', 'off', 'Name', 'MDP')
set(fig_mdp, 'toolbar', 'none')

set(fig_mdp, 'position', [262 62 828 732], 'color', 'w') 
fig_mdp.Color = 'w';

% data = zeros(n_unique_actions, 1);
x = ceil(sqrt(n_unique_actions));
% x = ceil(sqrt(length(main_actions)));

for naction = 1:n_unique_actions
    
    motor_out = motor_combs(naction, :);
    
    subplot(x, x, naction)
    imagesc(mdp.T(:,:,naction), [0 0.5])
    title(horzcat('Action: ', num2str(naction), '.  L: ', num2str(motor_out(1)), ',  R: ', num2str(motor_out(2))))
    ylabel('State')
    xlabel('Next State')
end

