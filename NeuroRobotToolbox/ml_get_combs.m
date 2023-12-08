
n_unique_actions = 10;
disp('Getting actions / combs...')
if get_combs
    
    rng(1)
    actions = kmeans(torque_data, n_unique_actions);
    n_unique_actions = length(unique(actions));
    motor_combs = zeros(2, n_unique_actions);

    figure(1)
    clf
    gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*4, torque_data(:,2)+randn(size(torque_data(:,2)))*4, actions, [],[],[], 'off')
    hold on
    for naction = 1:n_unique_actions
        motor_combs(:,naction) = mean(torque_data(actions == naction, :));
        text(motor_combs(1,naction), motor_combs(2,naction), num2str(naction), 'fontsize', 16, 'fontweight', 'bold')
    end
    axis padded
    set(gca, 'yscale', 'linear')
    title('Actions')
    xlabel('Torque 1')
    ylabel('Torque 2')
    drawnow
    
    save(strcat(nets_dir_name, net_name, '-actions'), 'actions')
    save(strcat(nets_dir_name, net_name, '-motor_combs'), 'motor_combs')
else
    load(strcat(nets_dir_name, net_name, '-actions'))
    load(strcat(nets_dir_name, net_name, '-motor_combs'))
end
