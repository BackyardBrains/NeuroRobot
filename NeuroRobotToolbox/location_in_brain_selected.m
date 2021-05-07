
% If no design action is in progress

% Disable unavailable buttons
set(button_add_neuron, 'enable', 'off')
set(button_add_network, 'enable', 'off')
set(button_return_to_runtime, 'enable', 'off')

if fig_design.UserData == 0 && ~exist('presynaptic_neuron', 'var')
    
    % If adding a single neuron
    if neuron_or_network == 1
        
        % Log command
        if save_data_and_commands
            this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
            command_log.entry(command_log.n).time = this_time;            
            command_log.entry(command_log.n).action = 'add single neuron to brain';
            command_log.n = command_log.n + 1;    
        end

        % Get the location of the new neuron from the user
        mouse_location = get(gca, 'CurrentPoint');
        
        % If the location is inside the brain
        if sqrt(mouse_location(1, 1)^2 + mouse_location(1, 2)^2) < 2.8 % This should be a custom ROI (brain_im_xy)

            % Add neuron
            nneurons = nneurons + 1; % This should be carefully changed to 'presynaptic_neuron'
            neuron_xys(nneurons, :) = mouse_location(1,1:2);
            
            % Reset add neuron button color
            button_add_neuron.BackgroundColor = [0.8 0.8 0.8];
            
            % Design action: add neuron or network
            fig_design.UserData = 1;

            % Initial color
            neuron_cols(nneurons, 1:3) = [1 0.9 0.8];

            % Plot preliminary neuron
            temp_plot(1) = scatter(neuron_xys(nneurons,1), neuron_xys(nneurons,2), 700, zeros(1, 3), 'filled');
            temp_plot(2) = scatter(neuron_xys(nneurons,1), neuron_xys(nneurons,2), 400, neuron_cols(nneurons, 1:3), 'filled');
            temp_plot(3) = text(neuron_xys(nneurons,1), neuron_xys(nneurons,2), num2str(nneurons), 'fontsize', bfsize - 6, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

            % Initialize neuron variables
            connectome(nneurons, nneurons) = 0;
            da_connectome(nneurons, nneurons, 1) = 0; % is the synapse plastic (1 = yes, 2 = yes with reward)?
            da_connectome(nneurons, nneurons, 2) = 0; % pre-reinforcement synapse weight
            da_connectome(nneurons, nneurons, 3) = 0; % learning intensity variable
            neuron_contacts(nneurons, ncontacts) = 0;
            spikes_loop = zeros(nneurons, ms_per_step * nsteps_per_loop);
            vis_prefs(nneurons, :, :) = 0;
            dist_prefs(nneurons, 1) = 0;
            audio_prefs(nneurons, 1) = 0;
            network_ids(nneurons, 1) = 0;
            neuron_scripts(nneurons, 1) = 0;
            
            da_rew_neurons(nneurons, 1) = 0;
            bg_neurons(nneurons, 1) = 0;
            save_firing = zeros(nneurons, 1);
            if ext_cam_id
                save_firing = zeros(nneurons, ext_cam_nsteps, 'logical');
            end
            
            % Open selection menu
            text_heading = uicontrol('Style', 'text', 'String', 'What kind of neuron is this?', 'units', 'normalized', 'position', [0.02 0.95 0.29 0.03], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            

            % Type 1 button
            button_n1 = uicontrol('Style', 'pushbutton', 'String', 'Quiet', 'units', 'normalized', 'position', [0.02 0.9 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_n1, 'Callback', 'set_neuron_type;', 'FontSize', bfsize - 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.6 0.95 0.6])
            % Type 2 button
            button_n2 = uicontrol('Style', 'pushbutton', 'String', 'Occasionally active', 'units', 'normalized', 'position', [0.02 0.84 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_n2, 'Callback', 'set_neuron_type;', 'FontSize', bfsize - 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
            % Type 3 button
            button_n3 = uicontrol('Style', 'pushbutton', 'String', 'Highly active', 'units', 'normalized', 'position', [0.02 0.78 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_n3, 'Callback', 'set_neuron_type;', 'FontSize', bfsize - 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
            % Type 4 button
            button_n4 = uicontrol('Style', 'pushbutton', 'String', 'Generates bursts', 'units', 'normalized', 'position', [0.02 0.72 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_n4, 'Callback', 'set_neuron_type;', 'FontSize', bfsize - 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
            % Type 5 button
            button_n5 = uicontrol('Style', 'pushbutton', 'String', 'Bursts when activated', 'units', 'normalized', 'position', [0.02 0.66 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_n5, 'Callback', 'set_neuron_type;', 'FontSize', bfsize - 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
            % Type 6 button
            button_n6 = uicontrol('Style', 'pushbutton', 'String', 'Dopaminergic', 'units', 'normalized', 'position', [0.02 0.6 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_n6, 'Callback', 'set_neuron_type;', 'FontSize', bfsize - 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
            % Type 6 button
            button_n7 = uicontrol('Style', 'pushbutton', 'String', 'Striatal', 'units', 'normalized', 'position', [0.02 0.54 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_n7, 'Callback', 'set_neuron_type;', 'FontSize', bfsize - 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

            % A
            text_a = uicontrol('Style', 'text', 'String', 'a', 'units', 'normalized', 'position', [0.02 0.48 0.01 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_a = uicontrol('Style', 'edit', 'String', num2str(a_init), 'units', 'normalized', 'position', [0.03 0.48 0.03 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            % B
            text_b = uicontrol('Style', 'text', 'String', 'b', 'units', 'normalized', 'position', [0.07 0.48 0.01 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_b = uicontrol('Style', 'edit', 'String', num2str(b_init), 'units', 'normalized', 'position', [0.08 0.48 0.03 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            % C
            text_c = uicontrol('Style', 'text', 'String', 'c', 'units', 'normalized', 'position', [0.12 0.48 0.01 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_c = uicontrol('Style', 'edit', 'String', num2str(c_init), 'units', 'normalized', 'position', [0.13 0.48 0.03 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            % D
            text_d = uicontrol('Style', 'text', 'String', 'd', 'units', 'normalized', 'position', [0.17 0.48 0.01 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_d = uicontrol('Style', 'edit', 'String', num2str(d_init), 'units', 'normalized', 'position', [0.18 0.48 0.03 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            % ID
            text_id = uicontrol('Style', 'text', 'String', 'id', 'units', 'normalized', 'position', [0.23 0.48 0.02 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_id = uicontrol('Style', 'edit', 'String', num2str(max([max(network_ids) 1])), 'units', 'normalized', 'position', [0.25 0.48 0.03 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);

            % Wait for OK
            button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.4 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_confirm, 'Callback', 'fig_design.UserData = 0;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [1 0.6 0.2])
            waitfor(fig_design, 'UserData', 0)
            delete(button_confirm)

            % Update parameters
            a(nneurons, 1) = str2double(edit_a.String);
            b(nneurons, 1) = str2double(edit_b.String);
            c(nneurons, 1) = str2double(edit_c.String);
            d(nneurons, 1) = str2double(edit_d.String);
            v(nneurons, 1) = c(nneurons, 1) + 5 * randn;
            u = b .* v;
            network_ids(nneurons, 1) = str2double(edit_id.String);
            steps_since_last_spike(nneurons, 1) = nan;
            neuron_tones(nneurons, 1) = 0;
            nnetworks = length(unique(network_ids)); % There used to be a +1 hack here, removing, testing..
            network_drive = zeros(nnetworks, 3);
            neuron_cols(nneurons, :) = network_colors(network_ids(nneurons), :);
            
            % Remove menu
            delete(text_heading)
            delete(text_a)
            delete(edit_a)
            delete(text_b)
            delete(edit_b)
            delete(text_c)
            delete(edit_c)
            delete(text_d)
            delete(edit_d)
            delete(text_id)
            delete(edit_id)
            delete(temp_plot)
            delete(button_n1)
            delete(button_n2)
            delete(button_n3)
            delete(button_n4)   
            delete(button_n5)
            delete(button_n6)
            delete(button_n7)

            % Clear neurons
            clear presynaptic_neuron
        
            % Draw brain
            draw_brain
            
        end
        
    % If adding entire network    
    elseif neuron_or_network == 2
        
        % Command log
        if save_data_and_commands
            this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
            command_log.entry(command_log.n).time = this_time;        
            command_log.entry(command_log.n).action = 'add many neurons to brain';
            command_log.n = command_log.n + 1;
        end
        
        % Get the location of the new neuron from the user
        mouse_location = get(gca, 'CurrentPoint');

        % ...or if the location is outside the brain
        if sqrt(mouse_location(1,1)^2 + mouse_location(1,2)^2) < 2.2
            
            % Reset add neuron button color
            button_add_network.BackgroundColor = [0.8 0.8 0.8];
            
            % Design action: add neuron or network
            fig_design.UserData = 1;
            
            % Initial color
            col = [1 0.9 0.8];

            % Plot preliminary neuron
            temp_plot(1) = plot(mouse_location(1,1), mouse_location(1,2), 'marker', 'p', 'markersize', 20, 'linewidth', 2, 'markeredgecolor', 'k', 'markerfacecolor', [0.6 0.95 0.6]);
            
            % Open selection menu
            text_heading = uicontrol('Style', 'text', 'String', 'How many neurons in this network?', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);


            % How many neurons
            text_w1 = uicontrol('Style', 'text', 'String', 'Neurons:', 'units', 'normalized', 'position', [0.02 0.86 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_w1 = uicontrol('Style', 'edit', 'String', '1000', 'units', 'normalized', 'position', [0.23 0.86 0.05 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);

            % Probability of interconnection
            text_w2 = uicontrol('Style', 'text', 'String', 'Connectivity (%):', 'units', 'normalized', 'position', [0.02 0.79 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_w2 = uicontrol('Style', 'edit', 'String', '25', 'units', 'normalized', 'position', [0.23 0.79 0.05 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            
            % Fraction excitatory synapses
            text_w3 = uicontrol('Style', 'text', 'String', 'Synapse weights:', 'units', 'normalized', 'position', [0.02 0.72 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_w3 = uicontrol('Style', 'edit', 'String', '2', 'units', 'normalized', 'position', [0.23 0.72 0.05 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            
            % Fraction dopamine-responsive synapses
            text_w4 = uicontrol('Style', 'text', 'String', 'Reward learning (%):', 'units', 'normalized', 'position', [0.02 0.65 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_w4 = uicontrol('Style', 'edit', 'String', '0', 'units', 'normalized', 'position', [0.23 0.65 0.05 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            
            % Fraction sensory neurons
            text_w5 = uicontrol('Style', 'text', 'String', 'Visual input (%):', 'units', 'normalized', 'position', [0.02 0.58 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_w5 = uicontrol('Style', 'edit', 'String', '0', 'units', 'normalized', 'position', [0.23 0.58 0.05 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            
            % Fraction motor neurons
            text_w6 = uicontrol('Style', 'text', 'String', 'Motor output (%):', 'units', 'normalized', 'position', [0.02 0.51 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_w6 = uicontrol('Style', 'edit', 'String', '0', 'units', 'normalized', 'position', [0.23 0.51 0.05 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);

            % Network ID
            text_id = uicontrol('Style', 'text', 'String', 'Network ID:', 'units', 'normalized', 'position', [0.02 0.44 0.21 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_id = uicontrol('Style', 'edit', 'String', num2str(max([max(network_ids) 1])), 'units', 'normalized', 'position', [0.23 0.44 0.05 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
                
            % Wait for OK
            button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.36 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_confirm, 'Callback', 'fig_design.UserData = 0;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [1 0.6 0.2])
            waitfor(fig_design, 'UserData', 0)
            delete(button_confirm)
            design_action = 0;
            delete(temp_plot)
           
%             if nma
%                 nma_build % skipping NMA build for now, just using its
%                 neuron sizes
%             else
                
                % Get number of neurons in the network
                n = str2double(edit_w1.String);
                if n > 10000
                    n = 10000;
                    disp('Network size reduced to 10000 neurons')
                end

                % Get equally distributed points
                if large_brain
                    eqdist_const = 0.001;
                else
                    eqdist_const = 0.01;
                end
                if nma
                    eqdist_const = 0.001;
                end
                xx = eqdist_const * n + 0.6;
                npoints = round(2*sqrt(n));
                phi = (sqrt(5)+1)/2;
                for nneuron = 1:n
                    if nneuron > n - npoints
                        r = 1;
                    else
                        r = sqrt(nneuron-1/2)/sqrt(n-(npoints+1)/2);
                    end    
                    theta = 2*pi*nneuron/phi^2;
                    xys = [r*cos(theta), r*sin(theta)];
                    xys = xys * xx;
                    neuron_xys(nneurons + nneuron, :) = xys + mouse_location(1,1:2);
                end  

                % Update parameters
                for presynaptic_neuron = nneurons + 1:nneurons + n

                    % Neuron-neuron synapses
                    for postsynaptic_neuron = nneurons + 1:nneurons + n
                        connected = rand <= str2double(edit_w2.String) / 100;
                        connected = connected * sign(rand-0.3);
    %                     synapse_sign = sign((rand < str2double(edit_w3.String)) - 0.5);
                        weight = str2double(edit_w3.String);
                        connectome(presynaptic_neuron, postsynaptic_neuron) = connected * weight;
                        da_connectome(presynaptic_neuron, postsynaptic_neuron, 1) = rand <= str2double(edit_w4.String) / 100;
                        da_connectome(presynaptic_neuron, postsynaptic_neuron, 2) = connected * weight;   
                        da_connectome(presynaptic_neuron, postsynaptic_neuron, 3) = 0;  
                    end            

                    % Sensory input
                    sens_neuron = rand <= str2double(edit_w5.String) / 100;
                    this_contact = randsample(2,1);
                    neuron_contacts(presynaptic_neuron, this_contact) = sens_neuron;
                    if sens_neuron
                        this_val = 1;
                    else
                        this_val = 0;
                    end
                    vis_prefs(presynaptic_neuron, randsample(3,1), this_contact) = this_val;
                    dist_prefs(presynaptic_neuron, 1) = 0;
                    audio_prefs(presynaptic_neuron, 1) = 0;
                    bg_neurons(presynaptic_neuron, 1) = 0;

                    % Motor output
                    moto_neuron = rand <= str2double(edit_w6.String) / 100;
                    m_val = randsample(4,1);
                    moto(1).contacts = [6, 8];
                    moto(2).contacts = [7, 9];
                    moto(3).contacts = [10, 12];
                    moto(4).contacts = [11, 13];
                    neuron_contacts(presynaptic_neuron, moto(m_val).contacts) = moto_neuron * 250;              
                end

                % Other variables
                spikes_loop = zeros(nneurons + n, ms_per_step * nsteps_per_loop);
                a(nneurons + 1 : nneurons + n, 1) = a_init;
                if nma
                    b(nneurons + 1 : nneurons + n, 1) = 0.15;
                else
                    b(nneurons + 1 : nneurons + n, 1) = b_init;
                end
                c(nneurons + 1 : nneurons + n, 1) = c_init;
                d(nneurons + 1 : nneurons + n, 1) = d_init;
                v(nneurons + 1 : nneurons + n, 1) = c_init + 5 * randn(n,1);
                u = b .* v;
                network_ids(nneurons + 1 : nneurons + n, 1) = str2double(edit_id.String);
                col = network_colors(network_ids(nneurons), :);
                neuron_cols(nneurons + 1 : nneurons + n, 1:3) = repmat(col, [n, 1]);  
                da_rew_neurons(nneurons + 1 : nneurons + n, 1) = 0;
                steps_since_last_spike(nneurons + 1 : nneurons + n) = nan;
                neuron_tones(nneurons + 1 : nneurons + n, 1) = 0;
                neuron_scripts(nneurons + 1 : nneurons + n, 1) = 0;
                nneurons = nneurons + n;
                if ext_cam_id
                    save_firing = zeros(nneurons, ext_cam_nsteps, 'logical');
                end
                nnetworks = length(unique(network_ids));
                network_drive = zeros(nnetworks, 3);
%             end
            disp('Large network created')
                       
            % Remove menus
            delete(text_heading)
            delete(text_w1)
            delete(edit_w1)  
            delete(text_w2)
            delete(edit_w2) 
            delete(text_w3)
            delete(edit_w3) 
            delete(text_w4)
            delete(edit_w4) 
            delete(text_w5)
            delete(edit_w5)   
            delete(text_w6)
            delete(edit_w6) 
            delete(text_id)
            delete(edit_id) 
            
            % Clear neurons
            clear presynaptic_neuron     
            clear postsynaptic_neuron  
            
            % Draw brain
            draw_brain  
        else
            neuron_or_network = 1;
            button_add_neuron.BackgroundColor = [0.8 0.8 0.8];
            button_add_network.BackgroundColor = [0.8 0.8 0.8];
        end
        
    end
        

% If the design action is move neuron
elseif fig_design.UserData == 4
    
    % Get the location of the new neuron from the user
    mouse_location = get(gca, 'CurrentPoint');

    % If the location is outside the brain
    if sqrt(mouse_location(1,1)^2 + mouse_location(1,2)^2) < 2.2  

        % Set the new location
        neuron_xys(presynaptic_neuron, :) = [mouse_location(1,1), mouse_location(1,2)];
        
        % Draw the brain
        draw_brain
        
        % No design action
        fig_design.UserData = 0;
        
        % Remove instructions
        delete(text_heading)

        % Clear neurons
        clear presynaptic_neuron
        
    end
    
end

% Disable unavailable buttons
set(button_add_neuron, 'enable', 'on')
set(button_add_network, 'enable', 'on')
set(button_return_to_runtime, 'enable', 'on')

neuron_or_network = 1; % Default to adding single neuron if click brain directly

