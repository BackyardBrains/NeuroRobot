
if fig_design.UserData == 2 && (~exist('postsynaptic_neuron', 'var') && ~exist('postsynaptic_contact', 'var'))

    % Log command
    if save_data_and_commands
        this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
        command_log.entry(command_log.n).time = this_time;            
        command_log.entry(command_log.n).action = 'create neuron to speaker synapse';
        command_log.n = command_log.n + 1;
    end
            
    % Delete previous heading
    delete(text_heading)
    
    % Activate speaker contact
    contact_h(4).MarkerFaceColor = sel_col_core;  
    speaker_selected = 1;
%     this_val = 1000; % 2020-07-30 rem
    
    % Text
    text_heading = uicontrol('Style', 'text', 'String', 'Set or delete sound output', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

    if ~vocal && ~supervocal
        % Manual weight
        current_tone = neuron_tones(presynaptic_neuron, 1);
        text_w = uicontrol('Style', 'text', 'String', 'Hz (31 to 4978):', 'units', 'normalized', 'position', [0.02 0.69 0.16 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        edit_w = uicontrol('Style', 'edit', 'String', num2str(current_tone), 'units', 'normalized', 'position', [0.18 0.69 0.09 0.05], 'fontsize', bfsize - 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);    
 
        % Connect
        button_w1 = uicontrol('Style', 'pushbutton', 'String', 'Create sound output synapse', 'units', 'normalized', 'position', [0.02 0.85 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        set(button_w1, 'Callback', 'set_synapse_type', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.6 0.95 0.6])

        % Remove
        button_w2 = uicontrol('Style', 'pushbutton', 'String', 'Delete sound output synapse', 'units', 'normalized', 'position', [0.02 0.77 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        set(button_w2, 'Callback', 'set_synapse_type', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

        % Wait for OK        
        button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.61 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        set(button_confirm, 'Callback', 'fig_design.UserData = 0;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [1 0.6 0.2])
        waitfor(fig_design, 'UserData', 0)
        delete(button_confirm)  
    
    else

        % Words
        if supervocal
            current_tone = neuron_tones(presynaptic_neuron, 1);
            if current_tone
                current_word = audio_out_names{current_tone};
            else
                current_word = [];
            end
            
            % Select word
            text_load = uicontrol('Style', 'text', 'String', 'Select word', 'units', 'normalized', 'position', [0.02 0.87 0.26 0.05], ...
                'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
            clear word_string
            word_string{1} = '-- Create new word --';
            for nword = 1:(n_out_sounds + n_vis_prefs)
                word_string{nword + 1} = audio_out_names{nword};
            end
            popup_select_word = uicontrol('Style', 'popup', 'String', word_string, 'callback', 'update_popup_select_word', 'units', 'normalized', ...
                'position', [0.02 0.75 0.26 0.1], 'fontsize', bfsize, 'fontweight', gui_font_weight, 'FontName', gui_font_name);
            word_text_name = uicontrol('Style', 'text', 'String', 'Current word:', 'units', 'normalized', 'position', [0.02 0.68 0.26 0.05], ....
                'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
            word_edit_name = uicontrol('Style', 'edit', 'String', current_word, 'units', 'normalized', 'position', [0.02 0.61 0.26 0.05], 'fontsize', bfsize, ....
                'FontName', gui_font_name, 'fontweight', gui_font_weight);              
     
        else
            
            % Sound effects
            current_sound = neuron_tones(presynaptic_neuron, 1);  
            popup_select_sound = uicontrol('Style', 'popup', 'String', [audio_out_names vis_pref_names], 'units', 'normalized', 'position', [0.02 0.85 0.16 0.06], 'fontsize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            if current_sound
                popup_select_sound.Value = current_sound;
            end        
            
        end
        

        % Wait for OK        
        button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.53 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        set(button_confirm, 'Callback', 'fig_design.UserData = 0;', 'FontSize', bfsize, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [1 0.6 0.2])
        waitfor(fig_design, 'UserData', 0)
        delete(button_confirm)          
        
    end       
    
    if isempty(word_edit_name.String) && popup_select_word.Value == 1
        word_edit_name.String = 'What should I say?';
    end
        
    word_selection_val = popup_select_word.Value;
    if word_selection_val == 1
        word_name = word_edit_name.String;
    else
        word_name = popup_select_word.String{word_selection_val};
    end    
    
    % Update variables
    if ~vocal
        this_input = str2double(edit_w.String);
    end
    if ~vocal && (isnan(this_input) || this_input < 0 || this_input > 4978)
        this_input = 0;
        disp('Speaker input out of range.')
    end
    speaker_selected = 0;
    if ~vocal
        neuron_tones(presynaptic_neuron, 1) = this_input;
    end
    
    if supervocal
        if popup_select_word.Value == 1
            neuron_tones(presynaptic_neuron, 1) = length(audio_out_fs) + 1;        
%             this_wav = tts(word_name,'Microsoft Zira Desktop - English (United States)',[],16000);
            this_wav = tts(word_name,'Microsoft David Desktop - English (United States)',[],16000);
            this_wav = this_wav(find(this_wav,1,'first'):find(this_wav,1,'last'));
            audio_out_durations = [audio_out_durations length(this_wav)/16000];
            audio_out_wavs(length(audio_out_fs) + 1).y = this_wav;
            audio_out_names{length(audio_out_fs) + 1} = word_name;
            
            audio_out_fs(length(audio_out_fs) + 1) = 16000; % This is also a counter
            
            brain.audio_out_wavs = audio_out_wavs;
            brain.audio_out_names = audio_out_names;
            
        elseif popup_select_word.Value > 1
            neuron_tones(presynaptic_neuron, 1) = popup_select_word.Value - 1;
        end
            
        delete(text_load)
        delete(word_text_name)
        delete(word_edit_name)
    else
        neuron_tones(presynaptic_neuron, 1) = popup_select_sound.Value;
    end
    if neuron_tones(presynaptic_neuron, 1)
        neuron_contacts(presynaptic_neuron, 4) = 100; % this is just to get a good axon display
    end
%     if ~vocal && this_input == 0 % can this just be implemented as is?
%         neuron_contacts(presynaptic_neuron, 4) = 0;
%     end

    % Design action complete
    design_action = 0; % not read at the end, ugly hack

    % Delete buttons
    if ~vocal
        delete(button_w1)
        delete(button_w2)
        delete(text_w)
        delete(edit_w)
    else
        delete(popup_select_word)
    end
        
    % Delete growth cone
    delete(growth_cone)
    
    % Delete previous heading
    delete(text_heading)    

    % Draw brain
    draw_brain 

    % Clear neurons
    clear presynaptic_neuron
    clear postsynaptic_contact    
    
    % Disable unavailable buttons
    set(button_add_neuron, 'enable', 'on')
    set(button_add_network, 'enable', 'on')
    set(button_return_to_runtime, 'enable', 'on')       
    
end