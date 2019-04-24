
nnetworks = 3;
nsteps = 1000;

network_drive = zeros(nnetworks, 3);
data1 = zeros(1, nsteps);
data2 = zeros(nnetworks, nsteps);

for nstep = 1:nsteps
    th = 50 + randn * 15;
    for nnetwork = 1:nnetworks
%         if nstep > 500 && nstep < 900 && nnetwork == 2
%             network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + rand; % add sensory input  
%         end        
        if network_drive(nnetwork, 2) == 0 % if the network is not active
            network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + rand * 2; % add a little to the network's drive
            if network_drive(nnetwork, 1) > th && ~sum(network_drive(:, 2) ~= 0) % if the network crosses threshold and no network is active
                network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + 100; % add a lot to the network's drive
                network_drive(nnetwork, 2) = 1; % mark the network as active
                disp(horzcat('Network ', num2str(nnetwork), ' active'))
            end
        elseif network_drive(nnetwork, 2) == 1 % if the network is active
            other_nets = 1:nnetworks;
            other_nets(nnetwork) = [];
            network_drive(other_nets, 1) = network_drive(other_nets, 1) - rand * 2.5; % inhibit the other nets
            network_drive(nnetwork, 1) = network_drive(nnetwork, 1) - rand * 1.5; % and withdraw some of the network's drive
            if network_drive(nnetwork, 1) < th% if the network's drive falls below threshold
                network_drive(nnetwork, 1) = 0; % set it's drive to zero
                network_drive(nnetwork, 2) = 0; % and set it as no longer active
                disp(horzcat('Network ', num2str(nnetwork), ' inactive'))
            end
        end
    end
    network_drive(network_drive(:,1) < 0, 1) = 0; 
    this_network = find(network_drive(:, 2));
    if isempty(this_network)
        this_network = 0;
    end
    data1(1, nstep) = this_network;
    data2(:, nstep) = network_drive(:, 1);
end

figure(1)
clf
% set(1, 'color', 'w', 'position', [560 260 600/3 560/3])
set(1, 'color', 'w', 'position', [1921 1 1920 1003])
plot(0.1:0.1:nsteps/10, data2)
hold on
% plot([50 90], [155 155], 'color', 'k', 'linewidth', 1)
axis([0 nsteps/10 0 160])
xlabel('Time (s)')
ylabel('Network drive')
title('Action selection')
% export_fig('action_selection', '-r300', '-jpg', '-nocrop')

