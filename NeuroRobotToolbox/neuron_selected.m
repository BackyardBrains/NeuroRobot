
if ~exist('presynaptic_neuron', 'var') && fig_design.UserData ~= 9 && fig_design.UserData ~= 7
    % Disable Design buttons
    delete(button_add_neuron)
    delete(button_add_population)
    delete(button_add_algorithm)
    delete(button_add_agents)
    delete(button_add_brain)
    delete(button_save)
    delete(button_return_to_runtime)
end

% Remove any previous highlights
if exist('presynaptic_neuron', 'var') && design_action ~=2 && ...
        (~exist('postsynaptic_neuron', 'var') && ~exist('postsynaptic_contact', 'var')) ...
        && fig_design.UserData ~= 1 && fig_design.UserData ~= 8

    draw_neuron_edge.CData(presynaptic_neuron, :) = [0 0 0];
    draw_neuron_core.CData(presynaptic_neuron, :) = neuron_cols(presynaptic_neuron, :);
    
    delete(text_heading)
    delete(button1)
    delete(button2)
    delete(button3)
    delete(button4)
    delete(button5)
    delete(button_cancel)
    drawnow

    fig_design.UserData = 0;
end

design_action = 0;
if fig_design.UserData == 0

    fig_design.UserData = 9;
    design_action = 9;

    % Get presynaptic neuron
    mouse_location = get(gca, 'CurrentPoint');
    x = mouse_location(1,1);
    y = mouse_location(1,2);    
    presynaptic_neuron = 0;
    dists = zeros(nneurons, 1);
    for nneuron = 1:nneurons
        xdist = neuron_xys(nneuron, 1) - x;
        ydist = neuron_xys(nneuron, 2) - y;
        dists(nneuron) = sqrt(xdist^2 + ydist^2);
    end   
    [~, presynaptic_neuron] = min(dists);
    draw_neuron_edge.CData(presynaptic_neuron, :) = sel_col_edge;
    draw_neuron_core.CData(presynaptic_neuron, :) = sel_col_core;
    
    % Open selection menu
    text_heading = uicontrol('Style', 'text', 'String', 'Select an action', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

    % Type 1 button
    button1 = uicontrol('Style', 'pushbutton', 'String', 'Synapse', 'units', 'normalized', 'position', [0.02 0.85 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
    set(button1, 'Callback', 'extend_axon', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
    % Type 2 button
    button2 = uicontrol('Style', 'pushbutton', 'String', 'Properties', 'units', 'normalized', 'position', [0.02 0.77 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
    set(button2, 'Callback', 'edit_properties', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
    % Type 3 button
    button3 = uicontrol('Style', 'pushbutton', 'String', 'Move', 'units', 'normalized', 'position', [0.02 0.69 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
    set(button3, 'Callback', 'move_neuron', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
    % Type 4 button
    button4 = uicontrol('Style', 'pushbutton', 'String', 'Delete', 'units', 'normalized', 'position', [0.02 0.61 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
    set(button4, 'Callback', 'delete_neuron', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]) 
    % Type 5 button
    button5 = uicontrol('Style', 'pushbutton', 'String', 'Specials', 'units', 'normalized', 'position', [0.02 0.53 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
    set(button5, 'Callback', 'attach_script', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8]) 
    % Cancel button
    button_cancel = uicontrol('Style', 'pushbutton', 'String', 'Cancel', 'units', 'normalized', 'position', [0.02 0.45 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
    set(button_cancel, 'Callback', 'cancel_edit', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])  

% If a presynaptic neuron has already been selected and an axon is being extended
elseif fig_design.UserData == 2 && (~exist('postsynaptic_neuron', 'var') && ~exist('postsynaptic_contact', 'var'))
    
    % Command log
    if save_data_and_commands
        this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
        command_log.entry(command_log.n).time = this_time;    
        command_log.entry(command_log.n).action = 'create neuron to neuron synapse';
        command_log.n = command_log.n + 1;
    end

    % Delete previous heading
    delete(text_heading)
    
    % Get postsynaptic neuron or motor contact
    mouse_location = get(gca, 'CurrentPoint');
    x = mouse_location(1,1);
    y = mouse_location(1,2);      
    postsynaptic_neuron = 0;
    dists = zeros(nneurons, 1);
    for nneuron = 1:nneurons
        xdist = neuron_xys(nneuron, 1) - x;
        ydist = neuron_xys(nneuron, 2) - y;
        dists(nneuron) = sqrt(xdist^2 + ydist^2);
    end   
    [~, postsynaptic_neuron] = min(dists);
    draw_neuron_edge.CData(postsynaptic_neuron, :) = sel_col_edge;
    draw_neuron_core.CData(postsynaptic_neuron, :) = sel_col_core;
    
    % If the new synapse is neuron-to-neuron
    if presynaptic_neuron ~= postsynaptic_neuron
        
        delete(text_heading)
        delete(growth_cone)
        x1 = neuron_xys(presynaptic_neuron,1);
        x2 = neuron_xys(postsynaptic_neuron,1);
        y1 = neuron_xys(presynaptic_neuron,2);
        y2 = neuron_xys(postsynaptic_neuron,2); 
        slope = (y2-y1)/(x2-x1);
        dx = abs(x1- x2);
        dy = abs(y1- y2);
        rx = dx / (dx + dy);
        ry = dy / (dx + dy);         
        if x1 <= x2 && y1 <= y2
            x1 = x1 + adjust2 * rx;
            y1 = y1 + adjust2 * ry;
            x2 = x2 - adjust2 * rx;
            y2 = y2 - adjust2 * ry;            
        elseif x1 > x2 && y1 <= y2
            x1 = x1 - adjust2 * rx;
            y1 = y1 + adjust2 * ry;   
            x2 = x2 + adjust2 * rx;
            y2 = y2 - adjust2 * ry;             
        elseif x1 > x2 && y1 > y2
            x1 = x1 - adjust2 * rx;
            y1 = y1 - adjust2 * ry; 
            x2 = x2 + adjust2 * rx;
            y2 = y2 + adjust2 * ry;             
        elseif x1 <= x2 && y1 > y2
            x1 = x1 + adjust2 * rx;
            y1 = y1 - adjust2 * ry;     
            x2 = x2 - adjust2 * rx;
            y2 = y2 + adjust2 * ry;            
        end        
        growth_cone = plot([x1 x2], [y1 y2], 'linewidth', 2, 'color', sel_col_edge);
        
        % Text
        text_heading = uicontrol('Style', 'text', 'String', 'Select synapse properties', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

        % Excitatory button
        button_w1 = uicontrol('Style', 'pushbutton', 'String', 'Excitatory', 'units', 'normalized', 'position', [0.02 0.85 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        set(button_w1, 'Callback', 'set_synapse_type', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

        % Inhibitory button
        button_w2 = uicontrol('Style', 'pushbutton', 'String', 'Inhibitory', 'units', 'normalized', 'position', [0.02 0.77 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        set(button_w2, 'Callback', 'set_synapse_type', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

        % Manual weight
        current_weight = connectome(presynaptic_neuron, postsynaptic_neuron);
        if current_weight == 0
            current_weight = base_weight;
        end
        current_weight = num2str(current_weight);

        text_w = uicontrol('Style', 'text', 'String', 'Weight:', 'units', 'normalized', 'position', [0.02 0.69 0.16 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        edit_w = uicontrol('Style', 'edit', 'String', current_weight, 'units', 'normalized', 'position', [0.18 0.69 0.09 0.05], 'fontsize', bfsize + 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight);

        % Plastic
%         current_da_mod = num2str(da_connectome(presynaptic_neuron, postsynaptic_neuron, 1));
        text_mod = uicontrol('Style', 'text', 'String', 'Plastic', 'units', 'normalized', 'position', [0.02 0.62 0.06 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        check_mod = uicontrol('Style', 'checkbox', 'units', 'normalized', 'position', [0.08 0.63 0.02 0.05], 'BackgroundColor', fig_bg_col);        
         
        % Dopamine-modulated
        text_dmod = uicontrol('Style', 'text', 'String', 'Needs dopamine', 'units', 'normalized', 'position', [0.14 0.62 0.1 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        check_dmod = uicontrol('Style', 'checkbox', 'units', 'normalized', 'position', [0.24 0.63 0.02 0.05], 'BackgroundColor', fig_bg_col);           
        
        % There should be a cancel button here

        % Wait for OK
        button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.54 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        set(button_confirm, 'Callback', 'fig_design.UserData = 0;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [1 0.6 0.2])
        waitfor(fig_design, 'UserData', 0)
        delete(button_confirm)
        design_action = 0;
        delete(growth_cone)

        % Update variables
        this_input = str2double(edit_w.String);
        if ~isa(this_input, 'double')
            this_input = 0;
            disp('Synapse weight not a number. Automatically set to 0.')
        end        

        if this_input < -100
            this_input = -100;
            disp('Synapse weight too inhibitory. Automatically set to -100.')
        end

        if this_input > 100
            this_input = 100;
            disp('Synapse weight too excitatory. Automatically set to 100.')
        end

        connectome(presynaptic_neuron, postsynaptic_neuron) = this_input;
        if check_mod.Value && ~check_dmod.Value
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 1) = 1;
        elseif check_mod.Value && check_dmod.Value
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 1) = 2;
        else
            da_connectome(presynaptic_neuron, postsynaptic_neuron, 1) = 0;
        end
        da_connectome(presynaptic_neuron, postsynaptic_neuron, 2) = this_input;

        % Remove menus
        delete(text_heading)
        delete(text_w)
        delete(edit_w)
        delete(text_mod)
        delete(check_mod)          
        delete(text_dmod)
        delete(check_dmod)       
        delete(button_w1)
        delete(button_w2)
        
        % Draw brain
        draw_brain   
     
        % Clear neurons
        clear presynaptic_neuron
        clear postsynaptic_neuron
        
    else % If pre and postsynaptic neuron is same
        
        % Cancel everything
        fig_design.UserData = 0;
        design_action = 0;
        delete(growth_cone)
        delete(text_heading)
        
        % Draw brain
        draw_brain   
     
        % Clear neurons
        clear presynaptic_neuron
        clear postsynaptic_neuron        
        
    end
        
   
% If a sensory contact has been selected    
elseif fig_design.UserData == 6

    % Postsynaptic neuron selected
    fig_design.UserData = 7;
    
    % Delete previous heading
    delete(text_heading)
    
    % Select postsynaptic neuron
    mouse_location = get(gca, 'CurrentPoint');
    x = mouse_location(1,1);
    y = mouse_location(1,2);
    postsynaptic_neuron = 0;
    dists = zeros(nneurons, 1);
    for nneuron = 1:nneurons
        xdist = neuron_xys(nneuron, 1) - x;
        ydist = neuron_xys(nneuron, 2) - y;
        dists(nneuron) = sqrt(xdist^2 + ydist^2);
    end   
    [~, postsynaptic_neuron] = min(dists);
    draw_neuron_edge.CData(postsynaptic_neuron, :) = sel_col_edge;
    draw_neuron_core.CData(postsynaptic_neuron, :) = sel_col_core; 
    
    x1 = contact_xys(presynaptic_contact, 1);
    y1 = contact_xys(presynaptic_contact, 2);
    x2 = neuron_xys(postsynaptic_neuron, 1);
    y2 = neuron_xys(postsynaptic_neuron, 2); 
    slope = (y2-y1)/(x2-x1);
    dx = abs(x1- x2);
    dy = abs(y1- y2);
    rx = dx / (dx + dy);
    ry = dy / (dx + dy);         
    if x1 <= x2 && y1 <= y2
        x1 = x1 + adjust2 * rx;
        y1 = y1 + adjust2 * ry;
        x2 = x2 - adjust2 * rx;
        y2 = y2 - adjust2 * ry;            
    elseif x1 > x2 && y1 <= y2
        x1 = x1 - adjust2 * rx;
        y1 = y1 + adjust2 * ry;   
        x2 = x2 + adjust2 * rx;
        y2 = y2 - adjust2 * ry;             
    elseif x1 > x2 && y1 > y2
        x1 = x1 - adjust2 * rx;
        y1 = y1 - adjust2 * ry; 
        x2 = x2 + adjust2 * rx;
        y2 = y2 + adjust2 * ry;             
    elseif x1 <= x2 && y1 > y2
        x1 = x1 + adjust2 * rx;
        y1 = y1 - adjust2 * ry;     
        x2 = x2 - adjust2 * rx;
        y2 = y2 + adjust2 * ry;            
    end        
    growth_cone = plot([x1 x2], [y1 y2], 'linewidth', 2, 'color', sel_col_edge);     
    
    % Is the neuron already connected?
    existing_pref = neuron_contacts(postsynaptic_neuron, presynaptic_contact);
    
    % Connect the neuron
    neuron_contacts(postsynaptic_neuron, presynaptic_contact) = 1;

    % Bring up properties selection menu
    if sum(presynaptic_contact == [1 2]) % If input is visual
        
        % Command log
        if save_data_and_commands
            this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
            command_log.entry(command_log.n).time = this_time;    
            command_log.entry(command_log.n).action = 'create camera to neuron synapse';
            command_log.n = command_log.n + 1;
        end
        
        text_heading = uicontrol('Style', 'text', 'String', 'Select visual preference', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        
        popup_select_preference = uicontrol('Style', 'popup', 'String', vis_pref_names, 'units', 'normalized', 'position', [0.02 0.85 0.16 0.06], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        if existing_pref
            popup_select_preference.Value = find(vis_prefs(postsynaptic_neuron, :, presynaptic_contact));
        end
        
        % Option to delete existing sensory synapse
        delete_synapse = 0;
        button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.77 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'FontSize', bfsize + 4, 'BackgroundColor', [0.8 0.8 0.8]);
        set(button_confirm, 'Callback', 'fig_design.UserData = 0;')         
        if existing_pref
            button_stop = uicontrol('Style', 'pushbutton', 'String', 'Delete existing synapse', 'units', 'normalized', 'position', [0.02 0.69 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'FontSize', bfsize + 4, 'BackgroundColor', [0.8 0.8 0.8]);
            set(button_stop, 'Callback', 'fig_design.UserData = 0; delete_synapse = 1;')
        else
            button_stop = uicontrol('Style', 'pushbutton', 'String', 'Cancel', 'units', 'normalized', 'position', [0.02 0.69 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'FontSize', bfsize + 4, 'BackgroundColor', [0.8 0.8 0.8]);
            set(button_stop, 'Callback', 'fig_design.UserData = 0; delete_synapse = 1;')
        end
        
        % Wait for OK        
        waitfor(fig_design, 'UserData', 0)
        delete(button_confirm)
        delete(growth_cone)
        delete(button_stop)

        %% Modify brain
%         % Apply net lock
%         if popup_select_preference.Value > size(vis_prefs, 2)            
%             if isempty(trained_nets)
%                 if use_cnn
%                     trained_nets = 'GoogLeNet';
%                 else
%                     trained_nets = state_net_name;
%                 end
%                 disp(horzcat('Brain now requires this trained net to load: ', trained_nets))
%             else
%                 error('Unable to integrate second trained net. How did you get here? Should be impossible.')
%             end
%         end

        vis_prefs(postsynaptic_neuron, :, presynaptic_contact) = 0; % Clear all visual preferences - only one preference per eye-neuron pair
        vis_prefs(postsynaptic_neuron, popup_select_preference.Value, presynaptic_contact) = 1 - delete_synapse;

        if delete_synapse
            neuron_contacts(postsynaptic_neuron, presynaptic_contact) = 0;
        end

        % Remove menu
        delete(text_heading)
        delete(popup_select_preference)

    elseif presynaptic_contact == 3 % If input is auditory
        
        % Command log
        if save_data_and_commands
            this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
            command_log.entry(command_log.n).time = this_time;    
            command_log.entry(command_log.n).action = 'create microphone to neuron synapse';
            command_log.n = command_log.n + 1;        
        end
        
        % Set auditory preference
        text_heading = uicontrol('Style', 'text', 'String', 'Select auditory preference (Pitch, Hz)', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);        

        current_weight = num2str(audio_prefs(postsynaptic_neuron));
        text_w = uicontrol('Style', 'text', 'String', 'Hz (0 - 5000):', 'units', 'normalized', 'position', [0.02 0.85 0.16 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        edit_w = uicontrol('Style', 'edit', 'String', current_weight, 'units', 'normalized', 'position', [0.18 0.85 0.09 0.06], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);

        delete_synapse = 0;
        button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.77 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'FontSize', bfsize + 4, 'BackgroundColor', [0.8 0.8 0.8]);
        set(button_confirm, 'Callback', 'fig_design.UserData = 0;')         
        if existing_pref
            button_stop = uicontrol('Style', 'pushbutton', 'String', 'Delete existing synapse', 'units', 'normalized', 'position', [0.02 0.69 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'FontSize', bfsize + 4, 'BackgroundColor', [0.8 0.8 0.8]);
            set(button_stop, 'Callback', 'fig_design.UserData = 0; delete_synapse = 1;')
        else
            button_stop = uicontrol('Style', 'pushbutton', 'String', 'Cancel', 'units', 'normalized', 'position', [0.02 0.69 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'FontSize', bfsize + 4, 'BackgroundColor', [0.8 0.8 0.8]);
            set(button_stop, 'Callback', 'fig_design.UserData = 0; delete_synapse = 1;')
        end
        
        % Wait for OK        
        waitfor(fig_design, 'UserData', 0)
        delete(button_confirm)
        delete(growth_cone)
        delete(button_stop)
        
        % Update variables
        this_input = round(str2double(edit_w.String));
        if ~isa(this_input, 'double') || this_input < 0 || this_input > 5000
            this_input = 0;
            disp('Hz out of range.')
        end
        if delete_synapse
            neuron_contacts(postsynaptic_neuron, presynaptic_contact) = 0;
            audio_prefs(postsynaptic_neuron) = 0;
        else
            audio_prefs(postsynaptic_neuron) = this_input;
        end   

        % Remove menu
        delete(text_heading)
        delete(text_w)
        delete(edit_w)
        
%         design_action = 0;

    elseif presynaptic_contact == 5 % If input is distance
        
        % Command log
        if save_data_and_commands
            this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
            command_log.entry(command_log.n).time = this_time;    
            command_log.entry(command_log.n).action = 'create distance sensor to neuron synapse';
            command_log.n = command_log.n + 1;        
        end
        
        text_heading = uicontrol('Style', 'text', 'String', 'Select distance preference', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        
        popup_select_preference = uicontrol('Style', 'popup', 'String', dist_pref_names, 'units', 'normalized', 'position', [0.02 0.85 0.16 0.06], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);    
        if existing_pref
            popup_select_preference.Value = dist_prefs(postsynaptic_neuron);
        end
        
        % Option to delete existing sensory synapse
        delete_synapse = 0;
        button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.77 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'FontSize', bfsize + 4, 'BackgroundColor', [0.8 0.8 0.8]);
        set(button_confirm, 'Callback', 'fig_design.UserData = 0;')         
        if existing_pref
            button_stop = uicontrol('Style', 'pushbutton', 'String', 'Delete existing synapse', 'units', 'normalized', 'position', [0.02 0.69 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'FontSize', bfsize + 4, 'BackgroundColor', [0.8 0.8 0.8]);
            set(button_stop, 'Callback', 'fig_design.UserData = 0; delete_synapse = 1;')
        else
            button_stop = uicontrol('Style', 'pushbutton', 'String', 'Cancel', 'units', 'normalized', 'position', [0.02 0.69 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'FontSize', bfsize + 4, 'BackgroundColor', [0.8 0.8 0.8]);
            set(button_stop, 'Callback', 'fig_design.UserData = 0; delete_synapse = 1;')            
        end      
        
        % Wait for OK        
        set(button_confirm, 'Callback', 'fig_design.UserData = 0;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [1 0.6 0.2])
        waitfor(fig_design, 'UserData', 0)
        delete(button_confirm)
        delete(growth_cone)
        delete(button_stop)
        
        % Update variables
        if delete_synapse
            neuron_contacts(postsynaptic_neuron, presynaptic_contact) = 0;
            dist_prefs(postsynaptic_neuron) = 0;
        else
            dist_prefs(postsynaptic_neuron) = popup_select_preference.Value;
        end

        % Remove menu
        delete(text_heading)
        delete(popup_select_preference)
        
    end

    % Draw brain
    draw_brain

    % Clear neurons and contacts
    clear presynaptic_contact
    clear postsynaptic_neuron
    
end

if ~exist('presynaptic_neuron', 'var') && fig_design.UserData ~= 9 && fig_design.UserData ~= 7
    design_buttons
end

% Design action: add neuron-neuron or neuron-motor synapse
if (~exist('postsynaptic_neuron', 'var') && ~exist('postsynaptic_contact', 'var')) ...
        && fig_design.UserData ~= 1 && fig_design.UserData ~= 8 % ugly hack
    
    fig_design.UserData = design_action;
end
