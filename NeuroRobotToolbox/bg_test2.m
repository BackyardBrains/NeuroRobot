
nstates = 12;
nsteps = 100000;
nnetworks = 3;
cued_network = 2;

baseline = -0.9;
weak_cue = 0.2; % 1;
strong_cue = 1; % 2;
reward = 4;
low_d2 = -0.5;

raw_drive = zeros(nstates, nnetworks, nsteps);
data = zeros(nstates, nnetworks, 2);

fig1 = figure(1);
clf
set(fig1, 'color', 'w', 'position', [1 41 1536 749])

for nstate = 1:nstates
    if nstate == 1
        state_name = 'Baseline';
        drive_delta = 0;
        cue_delta = 0;
        dopamine_delta = 0;
        
    elseif nstate == 2
        state_name = 'Baseline + Weak cue';
        drive_delta = 0;
        cue_delta = weak_cue;
        dopamine_delta = 0;
        
    elseif nstate == 3
        state_name = 'Baseline + Strong cue';
        drive_delta = 0;
        cue_delta = strong_cue;
        dopamine_delta = 0;
        
    elseif nstate == 4
        state_name = 'Baseline + Reward';
        drive_delta = 0;
        cue_delta = 0;
        dopamine_delta = reward;
        
    elseif nstate == 5
        state_name = 'Baseline + Weak cue + Reward';
        drive_delta = 0;
        cue_delta = weak_cue;
        dopamine_delta = reward;
        
    elseif nstate == 6
        state_name = 'Baseline + Strong cue + Reward';
        drive_delta = 0;
        cue_delta = strong_cue;
        dopamine_delta = reward;
        
    elseif nstate == 7
        state_name = 'Low dopamine';
        drive_delta = low_d2;
        cue_delta = 0;
        dopamine_delta = 0;

    elseif nstate == 8
        state_name = 'Low dopamine + Weak cue';
        drive_delta = low_d2;
        cue_delta = weak_cue;
        dopamine_delta = 0;
        
    elseif nstate == 9
        state_name = 'Low dopamine + Strong cue';
        drive_delta = low_d2;
        cue_delta = strong_cue;        
        dopamine_delta = 0; 
        
    elseif nstate == 10
        state_name = 'Low dopamine + Reward';
        drive_delta = low_d2;
        cue_delta = 0;
        dopamine_delta = reward;
        
    elseif nstate == 11
        state_name = 'Low dopamine + Weak cue + Reward';
        drive_delta = low_d2;
        cue_delta = weak_cue;        
        dopamine_delta = reward;
        
    elseif nstate == 12
        state_name = 'Low dopamine + Strong cue + Reward';
        drive_delta = low_d2;
        cue_delta = strong_cue;        
        dopamine_delta = reward;
        
    end
    
    disp(state_name)
    
    network_drive = zeros(nnetworks, 2);
    selection_data = [];
    action_duration = 0;
    duration_data = [];    
    
    for nstep = 1:nsteps

        th = 50 + randn * 15;

        network_order = randsample(nnetworks, nnetworks);
        for nnetwork = network_order'
            
            network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + baseline + drive_delta * rand;
            if nnetwork == cued_network
                network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + cue_delta * rand;
            end
            
            if network_drive(nnetwork, 2) == 0 % if the network is not active
                network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + rand * 2; % add a little to the network's drive
                if network_drive(nnetwork, 1) > th && ~sum(network_drive(:, 2) ~= 0) % if the network crosses threshold and no network is active
                    selection_data = [selection_data; nnetwork];
                    action_duration = 1;
                    network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + 150; % add a lot to the network's drive
                    network_drive(nnetwork, 2) = 1; % mark the network as active
%                     disp(horzcat('Network ', num2str(nnetwork), ' active'))
                end
            elseif network_drive(nnetwork, 2) == 1 % if the network is active
                other_nets = 1:nnetworks;
                other_nets(nnetwork) = [];
                network_drive(other_nets, 1) = network_drive(other_nets, 1) - rand * 2.5; % inhibit the other nets
                network_drive(nnetwork, 1) = network_drive(nnetwork, 1) - rand * 3.5; % and withdraw some of the network's drive
                network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + dopamine_delta * rand; % dopamine delta
                
                if network_drive(nnetwork, 1) < th % if the network's drive falls below threshold
                    duration_data = [duration_data; action_duration];
                    action_duration = 0;
                    network_drive(nnetwork, 1) = 0; % set it's drive to zero
                    network_drive(nnetwork, 2) = 0; % and set it as no longer active
%                     disp(horzcat('Network ', num2str(nnetwork), ' inactive'))
                elseif action_duration
                    action_duration = action_duration + 1;
                end

            end
        end
        
        this_network = find(network_drive(:, 2)); % find the active network
        [~, j] = max(network_drive(:, 1)); % find the network with highest drive
        if this_network ~= j % if the active network is not the network with the highest drive 
            network_drive(this_network, 1) = network_drive(this_network, 1) - 30 * rand; % reduce the active network's drive significantly
        end

        network_drive(network_drive(:,1) < 0, 1) = 0;
        network_drive(network_drive(:,1) > 250, 1) = 250; 
        this_network = find(network_drive(:, 2));
        if isempty(this_network)
            this_network = 0;
        end
        raw_drive(nstate, :, nstep) = network_drive(:,1);
        
    end


            
    
    subplot(4,3,nstate)

    plot(0.1:0.1:nsteps/10, squeeze(raw_drive(nstate, 1, :)), 'color', 'b')
    hold on
    plot(0.1:0.1:nsteps/10, squeeze(raw_drive(nstate, 2, :)), 'color', [0 0.7 0])
    plot(0.1:0.1:nsteps/10, squeeze(raw_drive(nstate, 3, :)), 'color', 'r')

    axis([0 nsteps/10 0 250])
    xlabel('Time (s)')
    ylabel('Network drive')

    selection_data = selection_data(1:length(duration_data));
    
    
    for ii = 1:nnetworks
        data(nstate, ii, 1) = sum(selection_data == ii);
        data(nstate, ii, 2) = sum(duration_data(selection_data == ii)) / nsteps;    
    end
    
    title(state_name)

end


