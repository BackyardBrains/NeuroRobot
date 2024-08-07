
% If no design action is in progress

if (fig_design.UserData ~= 6) && (fig_design.UserData ~= 1)
    % Disable Design buttons
    delete(button_add_neuron)
    delete(button_add_population)
    delete(button_add_algorithm)
    delete(button_add_agents)
    delete(button_add_brain)
    delete(button_save)
    delete(button_return_to_runtime)
end

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
        if sqrt(mouse_location(1, 1)^2 + mouse_location(1, 2)^2) < 2.8 % This should be a custom ROI (brainim_xy)
            
            % Add neuron
            nneurons = nneurons + 1; % This should be carefully changed to 'presynaptic_neuron'
            neuron_xys(nneurons, :) = mouse_location(1,1:2);
                       
            % Design action: add neuron or network
            fig_design.UserData = 1;
            
            % Initial color
            neuron_cols(nneurons, 1:3) = [1 0.9 0.8];
            
            % Plot preliminary neuron
            temp_plot(1) = scatter(neuron_xys(nneurons,1), neuron_xys(nneurons,2), 700, zeros(1, 3), 'filled');
            temp_plot(2) = scatter(neuron_xys(nneurons,1), neuron_xys(nneurons,2), 400, neuron_cols(nneurons, 1:3), 'filled');
            if draw_neuron_numbers
                temp_plot(3) = text(neuron_xys(nneurons,1), neuron_xys(nneurons,2), num2str(nneurons), 'fontsize', bfsize + 2, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            end
            
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

            % Open selection menu
            text_heading = uicontrol('Style', 'text', 'String', 'What kind of neuron is this?', 'units', 'normalized', 'position', [0.02 0.95 0.29 0.03], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            
            % Type 1 button
            button_n1 = uicontrol('Style', 'pushbutton', 'String', 'Quiet', 'units', 'normalized', 'position', [0.02 0.9 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_n1, 'Callback', 'set_neuron_type;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.6 0.95 0.6])
            % Type 2 button
            button_n2 = uicontrol('Style', 'pushbutton', 'String', 'Occasionally active', 'units', 'normalized', 'position', [0.02 0.84 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_n2, 'Callback', 'set_neuron_type;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
            % Type 3 button
            button_n3 = uicontrol('Style', 'pushbutton', 'String', 'Highly active', 'units', 'normalized', 'position', [0.02 0.78 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_n3, 'Callback', 'set_neuron_type;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
            % Type 4 button
            button_n4 = uicontrol('Style', 'pushbutton', 'String', 'Generates bursts', 'units', 'normalized', 'position', [0.02 0.72 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_n4, 'Callback', 'set_neuron_type;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
            % Type 5 button
            button_n5 = uicontrol('Style', 'pushbutton', 'String', 'Bursts when activated', 'units', 'normalized', 'position', [0.02 0.66 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_n5, 'Callback', 'set_neuron_type;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
            % Type 6 button
            button_n6 = uicontrol('Style', 'pushbutton', 'String', 'Dopaminergic', 'units', 'normalized', 'position', [0.02 0.6 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_n6, 'Callback', 'set_neuron_type;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
            % Type 6 button
            button_n7 = uicontrol('Style', 'pushbutton', 'String', 'Striatal', 'units', 'normalized', 'position', [0.02 0.54 0.26 0.05], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_n7, 'Callback', 'set_neuron_type;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
            
            % A
            text_a = uicontrol('Style', 'text', 'String', 'a', 'units', 'normalized', 'position', [0.02 0.48 0.01 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_a = uicontrol('Style', 'edit', 'String', num2str(a_init), 'units', 'normalized', 'position', [0.03 0.48 0.03 0.05], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            % B
            text_b = uicontrol('Style', 'text', 'String', 'b', 'units', 'normalized', 'position', [0.07 0.48 0.01 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_b = uicontrol('Style', 'edit', 'String', num2str(b_init), 'units', 'normalized', 'position', [0.08 0.48 0.03 0.05], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            % C
            text_c = uicontrol('Style', 'text', 'String', 'c', 'units', 'normalized', 'position', [0.12 0.48 0.01 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_c = uicontrol('Style', 'edit', 'String', num2str(c_init), 'units', 'normalized', 'position', [0.13 0.48 0.03 0.05], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            % D
            text_d = uicontrol('Style', 'text', 'String', 'd', 'units', 'normalized', 'position', [0.17 0.48 0.01 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_d = uicontrol('Style', 'edit', 'String', num2str(d_init), 'units', 'normalized', 'position', [0.18 0.48 0.03 0.05], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            % ID
            text_id = uicontrol('Style', 'text', 'String', 'id', 'units', 'normalized', 'position', [0.23 0.48 0.02 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_id = uicontrol('Style', 'popup', 'String', letters(1:nnetworks+1), 'units', 'normalized', 'position', [0.25 0.48 0.03 0.05], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            edit_id.Value = 1;

            % Wait for OK
            button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.4 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_confirm, 'Callback', 'fig_design.UserData = 0;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [1 0.6 0.2])
            waitfor(fig_design, 'UserData', 0)
            delete(button_confirm)
            
            % Update parameters
            a(nneurons, 1) = str2double(edit_a.String);
            b(nneurons, 1) = str2double(edit_b.String);
            c(nneurons, 1) = str2double(edit_c.String);
            d(nneurons, 1) = str2double(edit_d.String);
            v(nneurons, 1) = c(nneurons, 1) + 5 * randn;
            u = b .* v;
            network_ids(nneurons, 1) = edit_id.Value;
            steps_since_last_spike(nneurons, 1) = nan;
            neuron_tones(nneurons, 1) = 0;
            nnetworks = length(unique(network_ids)); % There used to be a +1 hack here, removing, testing..
            network_drive = zeros(nnetworks, 3);
            
            if bg_colors
                if bg_neurons(nneurons)
                    neuron_cols(nneurons, :) = network_colors(network_ids(nneurons), :);
                else
                    neuron_cols(nneurons, :) = [1 0.9 0.8];
                end
            else
                neuron_cols(nneurons, :) = [1 0.9 0.8];
            end
            
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
                        
            % Design action: add neuron or network
            fig_design.UserData = 1;
            
            % Initial color
            col = [1 0.9 0.8];
            
            % Plot preliminary neuron
            temp_plot(1) = plot(mouse_location(1,1), mouse_location(1,2), 'marker', 'p', 'markersize', 15, 'linewidth', 2, 'markeredgecolor', 'k', 'markerfacecolor', [0.6 0.95 0.6]);
            
            if multi_neuron_opt == 1 % Population
                design_population
            elseif multi_neuron_opt == 2 % Algorithm
                design_algorithm
            elseif multi_neuron_opt == 3 % Agent
                design_net
            elseif multi_neuron_opt == 4 % Brain
                design_brain
            end
            
            % Wait for OK
            button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.36 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            set(button_confirm, 'Callback', 'fig_design.UserData = 0;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [1 0.6 0.2])
            waitfor(fig_design, 'UserData', 0)
            delete(button_confirm)
            design_action = 0;
            delete(temp_plot)
            
            if multi_neuron_opt == 1 % Population
                create_population
            elseif multi_neuron_opt == 2 % Algorithm
                create_from_algorithm
                % create_combo_brain
            elseif multi_neuron_opt == 3 % Trained Net
                if ~strcmp(popup_select_nets.String, '--')
                    create_from_net
                    % trained_nets{2} = full_net_name;
                end
                delete(text_heading)
                delete(text_w1)
                delete(popup_select_nets)                  
            elseif multi_neuron_opt == 4 % Brain
                load_additional_brain
                if isempty(trained_nets_2{1}) || sum(strcmp(trained_nets, 'GoogLeNet'))
                    use_cnn = 1;
                    use_cnn_code
                    if use_custom_net % Cant handle regression nets
                        load(strcat(nets_dir_name, state_net_name, '-labels'))
                        unique_states = unique(labels);
                        n_unique_states = length(unique_states);
                        vis_pref_names = [vis_pref_names, labels'];
                    end
                    create_combo_brain
                    trained_nets = trained_nets_2;                    
                elseif isempty(trained_nets{1}) && sum(strcmp(trained_nets_2, 'GoogLeNet')) % Cant handle imported brain with custom net
                    use_cnn = 1;
                    use_cnn_code
                    create_combo_brain
                    trained_nets = trained_nets_2;
                else
                    disp('Cannot merge brain: different trained nets required')
                end
                delete(text_heading)
                delete(text_w1)
                delete(popup_select_brain)                
            end
            
            % Clear neurons
            clear presynaptic_neuron
            clear postsynaptic_neuron
            
            % Draw brain
            draw_brain
        else
            disp('Click inside the brain')
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

% Enable design buttons
if fig_design.UserData == 0
    design_buttons
end

neuron_or_network = 1; % Default to adding single neuron if click brain directly

