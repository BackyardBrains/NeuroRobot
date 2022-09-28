
if fig_design.UserData == 2 && (~exist('postsynaptic_neuron', 'var') && ~exist('postsynaptic_contact', 'var'))

    % Disable Design buttons
    delete(button_add_neuron)
    delete(button_add_population)
    delete(button_add_algorithm)
    delete(button_add_agents)
    delete(button_add_brain)
    delete(button_save)
    delete(button_return_to_runtime)
    
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
    text_heading = uicontrol('Style', 'text', 'String', 'Set or delete sound output', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

    if ~vocal && ~supervocal
        % Manual weight
        current_tone = neuron_tones(presynaptic_neuron, 1);
        text_w = uicontrol('Style', 'text', 'String', 'Hz (31 to 4978):', 'units', 'normalized', 'position', [0.02 0.69 0.16 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        edit_w = uicontrol('Style', 'edit', 'String', num2str(current_tone), 'units', 'normalized', 'position', [0.18 0.69 0.09 0.05], 'fontsize', bfsize + 2, 'fontname', gui_font_name, 'fontweight', gui_font_weight);    
 
        % Connect
        button_w1 = uicontrol('Style', 'pushbutton', 'String', 'Create sound output synapse', 'units', 'normalized', 'position', [0.02 0.85 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        set(button_w1, 'Callback', 'set_synapse_type', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.6 0.95 0.6])

        % Remove
        button_w2 = uicontrol('Style', 'pushbutton', 'String', 'Delete sound output synapse', 'units', 'normalized', 'position', [0.02 0.77 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        set(button_w2, 'Callback', 'set_synapse_type', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

        % Wait for OK        
        button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.61 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        set(button_confirm, 'Callback', 'fig_design.UserData = 0;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [1 0.6 0.2])
        waitfor(fig_design, 'UserData', 0)
        delete(button_confirm)  
    
    else

        % Words
        if supervocal
            current_tone = neuron_tones(presynaptic_neuron, 1);
            if current_tone && current_tone <= length(audio_out_names)
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
            popup_select_sound = uicontrol('Style', 'popup', 'String', word_string, 'callback', 'update_popup_select_word', 'units', 'normalized', ...
                'position', [0.02 0.75 0.26 0.1], 'fontsize', bfsize + 4, 'fontweight', gui_font_weight, 'FontName', gui_font_name);
            word_text_name = uicontrol('Style', 'text', 'String', 'Current word:', 'units', 'normalized', 'position', [0.02 0.68 0.26 0.05], ....
                'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
            word_edit_name = uicontrol('Style', 'edit', 'String', current_word, 'units', 'normalized', 'position', [0.02 0.61 0.26 0.05], 'fontsize', bfsize + 4, ....
                'FontName', gui_font_name, 'fontweight', gui_font_weight);   
            
            % Plastic
            text_m = uicontrol('Style', 'text', 'String', 'Male voice', 'units', 'normalized', 'position', [0.02 0.53 0.1 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            check_m = uicontrol('Style', 'checkbox', 'units', 'normalized', 'position', [0.12 0.54 0.02 0.05], 'BackgroundColor', fig_bg_col);        

            % Dopamine-modulated
            text_f = uicontrol('Style', 'text', 'String', 'Female voice', 'units', 'normalized', 'position', [0.14 0.53 0.1 0.05], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 4, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            check_f = uicontrol('Style', 'checkbox', 'units', 'normalized', 'position', [0.24 0.54 0.02 0.05], 'BackgroundColor', fig_bg_col);           

     
        else
            
            % Sound effects
            current_sound = neuron_tones(presynaptic_neuron, 1);  
            popup_select_sound = uicontrol('Style', 'popup', 'String', [audio_out_names], 'units', 'normalized', 'position', [0.02 0.85 0.16 0.06], 'fontsize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            if current_sound
                popup_select_sound.Value = current_sound;
            end        
            
        end
        

        % Wait for OK        
        button_confirm = uicontrol('Style', 'pushbutton', 'String', 'Confirm', 'units', 'normalized', 'position', [0.02 0.48 0.26 0.06], 'fontname', gui_font_name, 'fontweight', gui_font_weight);
        set(button_confirm, 'Callback', 'fig_design.UserData = 0;', 'FontSize', bfsize + 4, 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [1 0.6 0.2])
        waitfor(fig_design, 'UserData', 0)
        delete(button_confirm)          
        
    end       
    
    if supervocal 
        if isempty(word_edit_name.String) && popup_select_sound.Value == 1
            word_edit_name.String = 'What should I say?';
        end
        if popup_select_sound.Value == 1
            word_name = word_edit_name.String;
        else
            word_name = popup_select_sound.String{popup_select_sound.Value};
        end        
    end
        
   
    
    % Update variables
    if ~vocal
        this_input = str2double(edit_w.String);
    else
        this_input = popup_select_sound.Value;
    end
    if ~vocal && (isnan(this_input) || this_input < 0 || this_input > 4978)
        this_input = 0;
        disp('Speaker input out of range.')
    end
    speaker_selected = 0;
    neuron_tones(presynaptic_neuron, 1) = this_input;
    
    if supervocal
        if popup_select_sound.Value == 1
            neuron_tones(presynaptic_neuron, 1) = length(audio_out_fs) + 1;  
            
            if check_m.Value && ~check_f.Value
                this_wav = tts(word_name,'Microsoft David Desktop - English (United States)',[],16000);
            elseif check_m.Value && check_f.Value
                this_wav_m = tts(word_name,'Microsoft David Desktop - English (United States)',[],16000);
                this_wav_f = tts(word_name,'Microsoft Zira Desktop - English (United States)',[],16000);
                if length(this_wav_m) > length(this_wav_f)
                    this_wav_m = this_wav_m(1:length(this_wav_f));
                else
                    this_wav_f = this_wav_f(1:length(this_wav_m));
                end
                this_wav = this_wav_f + this_wav_m;
            else
                this_wav = tts(word_name,'Microsoft Zira Desktop - English (United States)',[],16000);
            end

            this_wav = this_wav(find(this_wav,1,'first'):find(this_wav,1,'last'));
            audio_out_durations = [audio_out_durations length(this_wav)/16000];
            audio_out_wavs(length(audio_out_fs) + 1).y = this_wav;
            audio_out_names{length(audio_out_fs) + 1} = word_name;
            
            audio_out_fs(length(audio_out_fs) + 1) = 16000; % This is also a counter
            
            brain.audio_out_wavs = audio_out_wavs;
            brain.audio_out_names = audio_out_names;
            
        elseif popup_select_sound.Value > 1
            neuron_tones(presynaptic_neuron, 1) = popup_select_sound.Value - 1;
        end
            
        delete(text_load)
        delete(word_text_name)
        delete(word_edit_name)
        delete(check_m)
        delete(text_m)
        delete(check_f)
        delete(text_f)

    end
    
    if exist('popup_select_sound', 'var')
        delete(popup_select_sound)        
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
    elseif exist('popup_select_sound', 'var')
        delete(popup_select_sound)
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
    
    % Enable design buttons
    design_buttons
    
end