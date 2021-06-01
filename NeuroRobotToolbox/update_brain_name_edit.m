
   
if popup_select_brain.Value == 1
    nneurons = 0;
    neuron_xys = [];
    connectome = [];
    da_connectome = [];
    neuron_contacts = [];
    vis_prefs = [];
    neuron_cols = [];    
    neuron_tones = 0;
    neuron_scripts = [];
    clear network_colors
    network_colors(1, :) = [1 0.9 0.8];

    draw_brain
else
    
    text_title.String = 'Loading brain...';
    text_load.String = '';
    set(button_bluetooth, 'enable', 'off')
    set(popup_select_brain, 'visible', 'off')
    set(brain_edit_name, 'enable', 'off')
    set(button_camera, 'enable', 'off')
    set(button_startup_complete, 'enable', 'off')
    drawnow    
    
    text_brain_info.String = popup_select_brain.String{popup_select_brain.Value};
    
    load(strcat('./Brains/', popup_select_brain.String{popup_select_brain.Value}, '.mat'))
    brain_edit_name.String = popup_select_brain.String{popup_select_brain.Value};
    nneurons = brain.nneurons;
    neuron_xys = brain.neuron_xys;
    connectome = brain.connectome;
    da_connectome = brain.da_connectome;
    neuron_contacts = brain.neuron_contacts;
    vis_prefs = brain.vis_prefs;
%     neuron_cols = brain.neuron_cols;
    da_rew_neurons = brain.da_rew_neurons;
    try
        bg_neurons = brain.bg_neurons;
    catch
        bg_neurons = zeros(nneurons, 1);
    end 
    neuron_scripts = brain.neuron_scripts;
    network_ids = brain.network_ids;
    
    % Neuron colors
    if bg_colors
        network_colors = linspecer(length(unique(network_ids)));
        network_colors(1, :) = [1 0.9 0.8];
        clear neuron_cols
        for nneuron = 1:nneurons
            if bg_neurons(nneuron)
                neuron_cols(nneuron, :) = network_colors(network_ids(nneuron), :);
            else
                neuron_cols(nneuron, :) = [1 0.9 0.8];
            end
        end
    else
        neuron_cols = repmat([1 0.9 0.8], [nneurons 1]);
    end
    
    neuron_tones = brain.neuron_tones;
    audio_prefs = brain.audio_prefs;
    
    if supervocal && isfield(brain, 'audio_out_wavs')
        n_also_these = size(brain.audio_out_wavs, 2);
        if n_also_these > (n_out_sounds + n_vis_prefs)
            for n_also_this = n_out_sounds + n_vis_prefs +1:n_also_these
                audio_out_wavs(n_also_this).y = brain.audio_out_wavs(n_also_this).y;
                audio_out_fs(n_also_this, 1) = 16000;
                audio_out_names{n_also_this} = brain.audio_out_names{n_also_this};
            end
        end
    end    
    
    draw_brain
    
    if bluetooth_present
        set(button_bluetooth, 'enable', 'on')
    end
    set(popup_select_brain, 'visible', 'on')
    set(brain_edit_name, 'enable', 'on')
    if camera_present && ~dis_cam_button
        set(button_camera, 'enable', 'on')
    end
    set(button_startup_complete, 'enable', 'on')
    text_title.String = 'Neurorobot Startup';
    text_load.String = 'Select brain';
    drawnow    
end

