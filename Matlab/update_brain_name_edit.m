
if popup_select_brain.Value == 1
    nneurons = [];
    neuron_xys = [];
    connectome = [];
    da_connectome = [];
    neuron_contacts = [];
    vis_prefs = [];
    neuron_cols = [];       
    draw_brain
else
    
    text_title.String = 'Loading brain...';
    text_load.String = '';
    set(button_bluetooth, 'enable', 'off')
    set(popup_select_brain, 'visible', 'off')
    set(brain_edit_name, 'enable', 'off')
    set(button_camera, 'enable', 'off')
    set(button_startup_complete, 'enable', 'off')
    set(button_exercises, 'enable', 'off')
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
    neuron_cols = brain.neuron_cols;
    da_rew_neurons = brain.da_rew_neurons;
    try
        bg_neurons = brain.bg_neurons;
    catch
        bg_neurons = zeros(nneurons, 1);
    end    
    draw_brain
    
    if bluetooth_present
        set(button_bluetooth, 'enable', 'on')
    end
    set(popup_select_brain, 'visible', 'on')
    set(brain_edit_name, 'enable', 'on')
    if camera_present
        set(button_camera, 'enable', 'on')
    end
    set(button_startup_complete, 'enable', 'on')
    set(button_exercises, 'enable', 'on')
    text_title.String = 'Neurorobot Startup';
    text_load.String = 'Select brain';
    drawnow    
end

