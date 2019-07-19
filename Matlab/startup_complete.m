


if isempty(edit_name.String) && popup_select_brain.Value == 1
    for ii = linspace(0, 0.94, 20)
        edit_name.BackgroundColor = [0.94 ii ii];
        pause(0.05)
    end
else
    button_startup_complete.BackgroundColor = [0.94 0.78 0.62];
    drawnow
    brain_selection_val = popup_select_brain.Value;
    if brain_selection_val == 1
        brain_name = edit_name.String;
        load_name = brain_name;
    else
        if strcmp(edit_name.String, popup_select_brain.String{brain_selection_val})
            brain_name = popup_select_brain.String{brain_selection_val};
            load_name = brain_name;
        else
            brain_name = edit_name.String;
            load_name = popup_select_brain.String{brain_selection_val};
            disp(horzcat(brain_name, ' is a clone of ', load_name))
        end
    end
    % Nothing prevents overwriting an existing brain
    disp(horzcat('Brain name = ', brain_name))
    if ~exist('net', 'var') && use_cnn
        tic
        net = googlenet;
        net_input_size = net.Layers(1).InputSize(1:2);
        disp(horzcat('googlenet loaded in ', num2str(round(toc)), ' s'))
    elseif ~exist('net', 'var') && use_rcnn
        tic
        net = alexnet;
        net_input_size = net.Layers(1).InputSize(1:2);
        disp(horzcat('alexnet loaded in ', num2str(round(toc)), ' s'))
        tic
        load('rcnn')
        disp(horzcat('rcnn loaded in ', num2str(round(toc)), ' s'))
    end
    if ~exist('rcnn', 'var') && use_rcnn
        tic
        load('rcnn')
        disp(horzcat('rcnn loaded in ', num2str(round(toc)), ' s'))
    end
    button_startup_complete.BackgroundColor = [0.6 0.95 0.6];
    
    if ~camera_present || ~exist('rak_cam', 'var')
        camera_present = 0;
        large_frame = zeros(720, 1280, 3, 'uint8');          
    end    
    if ~exist('bluetooth_modem', 'var')
        bluetooth_present = 0;
    end
    
    if second_screen_analysis

        delete(brain_ax)
        
        % Analysis 1
        analysis_1_ax = axes('position', [0.525 0.65 0.4 0.15]);
        set(analysis_1_ax, 'xtick', [], 'ytick', [])
        box on

        % Analysis 2
        analysis_2_ax = axes('position', [0.525 0.375 0.4 0.15]);
        set(analysis_2_ax, 'xtick', [], 'ytick', [])
        box on

        % Analysis 3
        analysis_3_ax = axes('position', [0.525 0.1 0.4 0.15]);
        set(analysis_3_ax, 'xtick', [], 'ytick', [])
        box on

    end

    drawnow
    pause(1)
    clear fig_design
    runtime
end

