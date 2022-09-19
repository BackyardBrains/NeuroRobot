

startup_post_fig_prep

if size(vis_prefs, 2) > n_basic_vis_features && ~(use_cnn || use_rcnn)
    if sum(sum(sum(vis_prefs(:, (n_basic_vis_features+1):end, :))))
        error('Brain needs AI. Set use_cnn or use_rcnn to 1.')
    end
end
% if ~isempty(neuron_tones) && popup_select_brain.Value ~= 1
%     if max(neuron_tones) > length(audio_out_fs) && vocal && ~supervocal % This is a mess
%         error('Brain needs tones. Set vocal to 0.')
%     end
% end
    
if rak_only
    rak_cam.writeSerial('d:120;d:220;d:320;d:420;d:520;d:620;')
elseif use_esp32
    esp32WebsocketClient.send('d:120;d:220;d:320;d:420;d:520;d:620;');
end

button_startup_complete.BackgroundColor = [0.94 0.78 0.62];
drawnow

% Nothing prevents overwriting an existing brain
disp(horzcat('Brain name = ', brain_name))
if ~exist('net', 'var') && use_cnn
    tic
%         g_net = googlenet; %%% <<<<< Commented out for packaging
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

button_startup_complete.BackgroundColor = [0.6 0.95 0.6];

if ~camera_present || ~exist('rak_cam', 'var')
    camera_present = 0;
    large_frame = zeros(720, 1280, 3, 'uint8');          
end    

drawnow
pause(1)
clear fig_design
runtime


