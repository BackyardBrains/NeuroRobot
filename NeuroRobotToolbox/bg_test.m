
nnetworks = 3;
nsteps = 8000;

network_drive = zeros(nnetworks, 3);
data1 = zeros(1, nsteps);
data2 = zeros(nnetworks, nsteps);

for nstep = 1:nsteps
    th = 50 + randn * 15;
    for nnetwork = 1:nnetworks
        if nstep > 1000 && nstep < 2000 && nnetwork == 2 % cue 1
            network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + 1 * rand; % delta
        end
        if nstep > 3000 && nstep < 7000 % d2 down
            network_drive(nnetwork, 1) = network_drive(nnetwork, 1) - 2 * rand; % delta
        end
        if nstep > 4000 && nstep < 5000 && nnetwork == 2 % cue 1
            network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + 1 * rand; % delta
        end        
        if network_drive(nnetwork, 2) == 0 % if the network is not active
            network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + rand * 2; % add a little to the network's drive
            if network_drive(nnetwork, 1) > th && ~sum(network_drive(:, 2) ~= 0) % if the network crosses threshold and no network is active
                network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + 150; % add a lot to the network's drive
                network_drive(nnetwork, 2) = 1; % mark the network as active
                disp(horzcat('Network ', num2str(nnetwork), ' active'))
            end
        elseif network_drive(nnetwork, 2) == 1 % if the network is active
            other_nets = 1:nnetworks;
            other_nets(nnetwork) = [];
            network_drive(other_nets, 1) = network_drive(other_nets, 1) - rand * 2.5; % inhibit the other nets
            network_drive(nnetwork, 1) = network_drive(nnetwork, 1) - rand * 3.5; % and withdraw some of the network's drive
            if network_drive(nnetwork, 1) < th % if the network's drive falls below threshold
                network_drive(nnetwork, 1) = 0; % set it's drive to zero
                network_drive(nnetwork, 2) = 0; % and set it as no longer active
                disp(horzcat('Network ', num2str(nnetwork), ' inactive'))
            end
            if nstep > 6000 % d2 down
                network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + 2 * rand; % delta
            end            
        end
    end
    network_drive(network_drive(:,1) < 0, 1) = 0; 
    network_drive(network_drive(:,1) > 250, 1) = 250; 
    this_network = find(network_drive(:, 2));
    if isempty(this_network)
        this_network = 0;
    end
    data1(1, nstep) = this_network;
    data2(:, nstep) = network_drive(:, 1);
end

figure(1)
clf
startup_fig_pos = get(0, 'screensize') + [0 40 0 -63];
fig_pos = get(0, 'screensize') + [0 40 0 -63];
% set(1, 'color', 'w', 'position', [560 260 600/3 560/3])
set(1, 'color', 'w', 'position', [1 41 1536 749])
% set(1, 'color', 'w', 'position', [1921 1 1920 1003])
plot(0.1:0.1:nsteps/10, data2)
hold on
plot([1000 2000] / 10, [230 230], 'color', [0.2 0.8 0.2], 'linewidth', 2)
plot([3000 7000] / 10, [235 235], 'color', 'k', 'linewidth', 2)
plot([4000 5000] / 10, [230 230], 'color', [0.2 0.8 0.2], 'linewidth', 2)
plot([6000 8000] / 10, [220 220], 'color', [0.2 0.2 0.8], 'linewidth', 2)

axis([0 nsteps/10 0 250])
xlabel('Time (s)')
ylabel('Network drive')
title('Action selection')
% export_fig('action_selection', '-r300', '-jpg', '-nocrop')
