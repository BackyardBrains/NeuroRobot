

if size(vis_prefs, 2) > 6 && ~(use_cnn || use_rcnn)
    if sum(sum(sum(vis_prefs(:, 7:end, :))))
        error('Brain needs AI. Set use_cnn or use_rcnn to 1.')
    end
end
if ~isempty(neuron_tones)
    if max(neuron_tones) > length(audio_out_fs) && vocal && ~supervocal % This is a mess
        error('Brain needs tones. Set vocal to 0.')
    end
end
    
if rak_only
    rak_cam.writeSerial('d:120;d:220;d:320;d:420;d:520;d:620;')
end
if isempty(brain_edit_name.String) && popup_select_brain.Value == 1
    for ii = linspace(0, 0.94, 20)
        brain_edit_name.BackgroundColor = [0.94 ii ii];
        pause(0.05)
    end
else
    button_startup_complete.BackgroundColor = [0.94 0.78 0.62];
    drawnow
    brain_selection_val = popup_select_brain.Value;
    if brain_selection_val == 1
        brain_name = brain_edit_name.String;
        load_name = brain_name;
    else
        if strcmp(brain_edit_name.String, popup_select_brain.String{brain_selection_val})
            brain_name = popup_select_brain.String{brain_selection_val};
            load_name = brain_name;
        else
            brain_name = brain_edit_name.String;
            load_name = popup_select_brain.String{brain_selection_val};
            disp(horzcat(brain_name, ' is a clone of ', load_name))
        end
    end
    % Nothing prevents overwriting an existing brain
    disp(horzcat('Brain name = ', brain_name))
    if ~exist('net', 'var') && use_cnn
        tic
        g_net = googlenet;
        net_input_size = g_net.Layers(1).InputSize(1:2);
        disp(horzcat('googlenet loaded in ', num2str(round(toc)), ' s'))
    elseif ~exist('net', 'var') && use_rcnn
        tic
        net_input_size = [227 227];
        load('rcnn5heads')
        disp(horzcat('rcnn loaded in ', num2str(round(toc)), ' s'))
    elseif use_cnn
        net_input_size = [227 227];
    elseif use_rcnn
        net_input_size = [224 224];
    end
%     if ~exist('rcnn', 'var') && use_rcnn
%         tic
%         load('rcnn')
%         disp(horzcat('rcnn loaded in ', num2str(round(toc)), ' s'))
%     end
    button_startup_complete.BackgroundColor = [0.6 0.95 0.6];
    
    if ~camera_present || ~exist('rak_cam', 'var')
        camera_present = 0;
        large_frame = zeros(720, 1280, 3, 'uint8');          
    end    
    if ~exist('bluetooth_modem', 'var')
        bluetooth_present = 0;
    end

    drawnow
    pause(1)
    clear fig_design
    runtime
end

