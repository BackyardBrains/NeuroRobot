
if nneurons
    
    spikes_step = zeros(nneurons, ms_per_step);
    I_step = zeros(nneurons, ms_per_step);

    % Calculate visual input current
    vis_I = zeros(nneurons, 1);
    for nneuron = 1:nneurons % ugly for loop, fix this
        for ncam = 1:2
            these_prefs = logical(vis_prefs(nneuron, :, ncam));
            %%% GoogleNet/Alexnet missing error here
            vis_I(nneuron) = vis_I(nneuron) + sum(vis_pref_vals(these_prefs, ncam));
        end
    end 
    
    % Calculate distance sensor input current
    dist_I = zeros(nneurons, 1);
    dist_I(dist_prefs == 1) = sigmoid(this_distance, dist_short, -1) * 50;
    dist_I(dist_prefs == 2) = sigmoid(this_distance, dist_med, -1) * 50;
    dist_I(dist_prefs == 3) = sigmoid(this_distance, dist_long, -1) * 50;

    % Calculate microphone input current
    audio_I = zeros(nneurons, 1);
    for nneuron = 1:nneurons
        if audio_prefs(nneuron)
            try
                soundvar_1 = round(audio_prefs(nneuron)); % Stated audio pref
                [~, soundvar_2] = min(abs(fx-soundvar_1)); % Closest spectrogram ind
                soundvar_3 = sound_spectrum(soundvar_2, nstep); % Amplitude at 
                audio_I(nneuron) = (soundvar_3 > audio_th) * 50; 
            catch
                disp('Cannot get audio_I')
            end
        end
    end

    % % Delays
    % delays = delays - 1;
    % audio_I(delays == 2) = 50;
    % counters = counters - firing;
    % dist_I(counters < 6 & counters > 0) = 50;

    % Run brain simulation
    for t = 1:ms_per_step
        
        % % Delays
        % delays(v > 30 & neuron_scripts == 4 & delays < 1) = 10;
        % counters(v > 30 & neuron_scripts == 5 & counters < 1) = 10;
        % v(v > 30 & neuron_scripts == 4 & delays ~= 2) = -65;
        
        % Add noise
        I = 5 * randn(nneurons, 1);
        
        % Find spiking neurons
        fired_now = v >= 30;
        spikes_step(fired_now, t) = 1;

        % Reset spiking v to c
        v(fired_now) = c(fired_now);

        % Adjust spiking u to d
        u(fired_now) = u(fired_now) + d(fired_now);

        % Add spiking synaptic weights to neuronal inputs
        I = I + sum(connectome(fired_now,:), 1)';

        % Add sensory input currents
        I = I + vis_I + dist_I + audio_I;
        I_step(:, t) = I;

        % Update v
        v = v + 0.5 * (0.04 * v.^2 + 5 * v + 140 - u + I);
        v = v + 0.5 * (0.04 * v.^2 + 5 * v + 140 - u + I); % Yes twice

        % Update u
        u = u + a .* (b .* v - u);

        % Avoid nans
        v(isnan(v)) = c(isnan(v));

    end

    try
    
        % BG select
        this_network = 0;
        if bg_brain
            th = 50 + randn * 15;
            
            for nnetwork = 2:nnetworks
                
                % Sensory boost
                these_neurons = bg_neurons & network_ids == nnetwork;
                if sum(these_neurons)
                    this_drive = sum(mean(I_step(these_neurons, :), 2)) * 0.5;
                    network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + this_drive;
                end
                
                if network_drive(nnetwork, 2) == 0 % if the network is not active
                    network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + rand * 2; % add a little to the network's drive
                    if network_drive(nnetwork, 1) > th && ~sum(network_drive(:, 2) ~= 0) % if the network crosses threshold and no network is active
                        network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + 150; % add a lot to the network's drive
                        network_drive(nnetwork, 2) = 1; % mark the network as active
                    end
                elseif network_drive(nnetwork, 2) == 1 % if the network is active
                    other_nets = 1:nnetworks;
                    other_nets(nnetwork) = [];
                    network_drive(other_nets, 1) = network_drive(other_nets, 1) - rand * 2.5; % inhibit the other nets
                    network_drive(nnetwork, 1) = network_drive(nnetwork, 1) - rand * 3.5; % and withdraw some of the network's drive
                    network_drive(nnetwork, 1) = network_drive(nnetwork, 1) + reward * 2.5; % tonic reward
                    if network_drive(nnetwork, 1) < th % if the network's drive falls below threshold
                        network_drive(nnetwork, 1) = 0; % set its drive to zero
                        network_drive(nnetwork, 2) = 0; % and set it as no longer active
                    end
                    network_drive(nnetwork, 3) = network_drive(nnetwork, 3) + reward; 
                end
            end
            network_drive(network_drive(:,1) < 0, 1) = 0; 
            network_drive(network_drive(:,1) > 250, 1) = 250; 
    
            this_network = find(network_drive(:, 2)); % find the active network
            
            [~, j] = max(network_drive(1:nnetworks, 1)); % find the network with highest drive
            if this_network ~= j % if the active network is not the network with the highest drive 
                network_drive(:, 1) = network_drive(:, 1) - 30 * rand; % reduce the active network's drive significantly
            end
            
            if isempty(this_network)
                this_network = -1;
            end
            down_neurons = network_ids ~= this_network(1) & network_ids ~= 1;
            spikes_step(down_neurons, :) = 0; % note, this means down neurons still spike to synapses during t
            drive_bar.YData = network_drive(2:end,1);
        end
        spikes_step(bg_neurons & network_ids ~= this_network, :) = 0;
        spikes_step(bg_neurons & network_ids == this_network, :) = 1;
        
        % Step data
        firing = sum(spikes_step, 2) > 0;
        steps_since_last_spike(firing) = 0;
        steps_since_last_spike = steps_since_last_spike + 1;
        
        % Create xfiring for analog MSN color
        xfiring = double(firing);
    %     msn_vals = network_drive(:,1);
    %     msn_vals(1) = [];
    %     msn_vals = msn_vals / 250;
    %     xfiring(logical(bg_neurons)) = msn_vals;
        
        % Learning (STDP)
        for nneuron = find(firing)' % for each spiking neuron
            presynaptic_neurons = connectome(:, nneuron) > 0; % find its presynaptic neurons
            recent_spikers = steps_since_last_spike < ltp_recency_th_in_steps; % find recently active neurons
            if reward
                plastic_synapses = da_connectome(:, nneuron, 1) > 0; % find plastic synapses
            else
                plastic_synapses = da_connectome(:, nneuron, 1) == 1; % find plastic synapses
            end
            these_neurons = presynaptic_neurons & recent_spikers & plastic_synapses; % reinforce these
            da_connectome(these_neurons, nneuron, 3) = da_connectome(these_neurons, nneuron, 3) + 1; % update learning intensity vector
            reinforcement = pulse_period * sigmoid(da_connectome(these_neurons, nneuron, 3), 100, 0.02) * 5 + (reward * 2 * pulse_period); % sigmoid learning
            connectome(these_neurons, nneuron) = connectome(these_neurons, nneuron) + round(reinforcement * 100) / 100;
            if sum(these_neurons)
                for presyn = find(these_neurons)'
                    w = connectome(presyn, nneuron);
                    w = round(w);
                    if draw_synapses
                        plot_neuron_synapses(presyn, nneuron, 1).LineWidth = (abs(w) / 12) + 1;
                    end
                    if draw_synapses && draw_synapse_strengths
                        try
                            plot_neuron_synapses(presyn, nneuron, 3).String = num2str(w);
                        catch
                            disp('Failed to edit plot_neuron_synapses String property in update_brain')                            
                        end
                    end
                end
            end
        end
    catch
        disp('Error A in update_brain')
    end

    try
        connectome = min(connectome, max_w); % enforce max weight
        da_connectome(:, :, 3) = da_connectome(:, :, 3) - 0.5;
        xx = da_connectome(:, :, 3);
        xx(xx < 0) = 0;
        da_connectome(:, :, 3) = xx;
    
        % Forgetting
        for nneuron = 1:nneurons % for each neuron
            plastic_synapses = find(da_connectome(nneuron, :, 1)); % find its plastic synapses
            for postsyn = plastic_synapses % for each plastic synapse
                current_w = connectome(nneuron, postsyn);
                original_w = da_connectome(nneuron, postsyn, 2);
                reinforcement = current_w - original_w;
                if reinforcement
                    loss_delay = steps_since_last_spike(nneuron) - ltp_recency_th_in_steps;
                    loss_delay(loss_delay < 0) = 0;
                    this_loss = floor(permanent_memory_th / reinforcement) * pulse_period * 1 * min(loss_delay/((1/pulse_period)*10), 1);
                    this_loss = min(this_loss, reinforcement);
                    connectome(nneuron, postsyn) = current_w - this_loss;
                    if this_loss
                        w = connectome(nneuron, postsyn);
                        w = round(w);
                        if draw_synapses
                            plot_neuron_synapses(nneuron,postsyn,1).LineWidth = ((abs(w) / 12) + 1) / 1;
                        end
                        if draw_synapses && draw_synapse_strengths
                            try
                                plot_neuron_synapses(nneuron, postsyn, 3).String = num2str(w);
                            catch
                                disp('No string property error')
                            end                                
                        end
                    end
                end
            end
        end
    catch
        error('Error B in update_brain')
    end

    % Store long activity
    spikes_loop(:, 1 + (nstep - 1) * ms_per_step : nstep * ms_per_step) = spikes_step;

    % Plot brain
    if bg_colors
        draw_neuron_core.CData(~firing, :) = neuron_cols(~firing, :);
        if rem(nstep, 2)
            draw_neuron_core.CData(firing, :) = neuron_cols(firing, :) * 0.4;
        else
            draw_neuron_core.CData(firing, :) = neuron_cols(firing, :) * 0.8;
        end
        draw_neuron_edge.CData(~firing, :) = repmat([0 0 0], [sum(~firing), 1]);
    else
        draw_neuron_core.CData = [1 - xfiring 1 - (xfiring * 0.25) 1 - xfiring] .* neuron_cols;
        draw_neuron_edge.CData = [zeros(nneurons, 1) xfiring * 0.5 zeros(nneurons, 1)] .* neuron_cols;
        draw_neuron_edge.CData = [zeros(nneurons, 1) zeros(nneurons, 1) zeros(nneurons, 1)] .* neuron_cols;
    end

    if bg_brain
        for nneuron = 1:nneurons % Risky
            try
                if bg_colors
                    this_col = network_colors(network_ids(nneuron), :);
                else
                    this_col = [1 0.9 0.8];
                end                
                
                if down_neurons(nneuron) && ~bg_neurons(nneuron) && network_ids(nneuron) > 1
                    draw_msn_skylt(nneuron, 1).MarkerFaceColor = 'k';
                    draw_msn_skylt(nneuron, 2).Color = 'w';
                    draw_msn_skylt(nneuron, 3).LineWidth = 20;
                    p1 = find(bg_neurons & network_ids == network_ids(nneuron), 1);
                    if ~isempty(p1)
                        plot_bg_lines(p1, nneuron).Color = this_col;
                    end
                elseif ~down_neurons(nneuron) && ~bg_neurons(nneuron) && network_ids(nneuron) > 1
                    draw_msn_skylt(nneuron, 1).MarkerFaceColor = 'w';
                    draw_msn_skylt(nneuron, 2).Color = 'k';
                    draw_msn_skylt(nneuron, 3).LineWidth = 2;
                    p1 = find(bg_neurons & network_ids == network_ids(nneuron), 1);
                    if ~isempty(p1)
                        plot_bg_lines(p1, nneuron).Color = this_col + ((1 - this_col) * 0.8);
                    end
                end

            catch
                disp('error in update brain')
            end
        end
    end
    
    % Plot activity
    [y, x] = find(spikes_loop);
    vplot.XData = x;
    vplot.YData = y;
    
    % Stop reward
    if reward
        reward = 0;
    end

end

