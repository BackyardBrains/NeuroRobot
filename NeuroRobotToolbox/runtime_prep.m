
set(button_startup_complete, 'enable', 'off')
drawnow


%% Robot settings
update_robot_select


%% App settings
% 1 = 'BG Color Scheme'
if sum(select_app.Value == 1)
    bg_colors = 1; % Use neuron color to indicate network ID, neuron flickering to indicate spikes  
else
    bg_colors = 0;
end

% 2 = 'Draw Neuron Numbers'   
if sum(select_app.Value == 2)
    draw_neuron_numbers = 1;
else
    draw_neuron_numbers = 0;
end

% 3 = 'Draw Synapse Weights'    
if sum(select_app.Value == 3)
    draw_synapse_strengths = 1;
else
    draw_synapse_strengths = 0;
end

% 4 = 'Record Data'
if sum(select_app.Value == 4)
    record_data = 1;
else
    record_data = 0;
end


%% Trained Nets settings
% 1 = '-none-' % popup menu requires selection
if sum(select_nets.Value == 1)
end

% 2 = 'GoogLeNet (generic objects)'
if sum(select_nets.Value == 2)
    use_cnn = 1;
else
    use_cnn = 0;
end

% 3 = 'AlexNet (custom objects)'
if sum(select_nets.Value == 3)
    use_rcnn = 1;
else
    use_rcnn = 0;
end

% 3 = 'Custom state and action nets'
if sum(select_nets.Value >= nimported)
    use_controllers = 1;
else
    use_controllers = 0;
end


%% Communication settings
audio_th = 5;             % Audio threshold (increase if sound spectrum looks too crowded)

% 1 = 'Microphone input'
if sum(select_communication.Value == 1)
    matlab_audio_rec = 1;
else
    matlab_audio_rec = 0;
end

% 2 = 'Custom sounds'
if sum(select_communication.Value == 2)
    vocal = 1;
else
    vocal = 0;
end

% 3 = 'Speak words'
if sum(select_communication.Value == 3)
    supervocal = 1; % Custom word output (text-to-speech - windows tested)
    vocal = 1; % Hack, needed for indexing
else
    supervocal = 0;
end

% 4 = 'Multi-tone speaker'
if sum(select_communication.Value == 4)
    matlab_speaker_ctrl = 1; % Multi tone output, fixes tone colission error but introduces step cuts  
else
    matlab_speaker_ctrl = 0;      
end


%% Clear
clear presynaptic_neuron
clear postsynaptic_neuron
clear postsynaptic_contact
clear neuron_xys
clear spikes_step


%% Calibrate distance sensor
esp_get_serial
if this_distance < 1000
    dist_short = 4;
    dist_med = 7;
    dist_long = 9;
else
    dist_short = 200;
    dist_med = 900;
    dist_long = 1400;
end

%% ML vars
if select_nets.Value > nimported
    full_net_name = option_nets{select_nets.Value};
    temp = strfind(full_net_name, '-');
    net_name = full_net_name(1:temp(1)-1);
    rl_type = full_net_name(temp(1)+1:temp(2)-1);
    agent_name = full_net_name(temp(2)+1:end);
else
    net_name = '';
end


%% Select brain
brain_name = brain_string{select_brain.Value};

load(strcat(brain_dir, brain_name, '.mat'))
load_brain

brain_support = 1;
if ~isempty(vision_net_lock)
    if (strcmp(vision_net_lock, 'GoogLeNet') && ~use_cnn) || ...
            (strcmp(vision_net_lock, 'AlexNet') && ~use_rcnn) || ...
            (~strcmp(vision_net_lock, 'GoogLeNet') && ~strcmp(vision_net_lock, 'AlexNet') && ~strcmp(vision_net_lock, net_name))
        disp(horzcat('Brain needs this net to see: ', vision_net_lock))
        brain_support = 0;
    end
end

if exist('rak_only', 'var') && brain_support    

    
    %% Clear timers - why is this used?
    if exist('runtime_pulse', 'var')
        stop(runtime_pulse)
        pause(1)
        delete(runtime_pulse)
    end
    clear step_timer
    clear life_timer
    disp('---------')
    
    
    %% Prepare
    microcircuit = 0;
    computer_name = getenv('COMPUTERNAME');
    user_name = getenv('USERNAME');
    user_name(user_name == ' ') = '_';
    max_w = 100;
    ltp_recency_th_in_sec = 2000; % must be >= pulse_period
    permanent_memory_th = 24;
    im3 = flipud(255 - ((255 - imread('workspace2.jpg'))));
    adjust2 = 0.29;
    letters = {'A', 'B', 'C', 'D', 'E',...
        'F', 'G', 'H', 'I', 'J',...
        'K', 'L', 'M', 'N', 'O', ...
        'P', 'Q'};
    net_input_size = [227 227];
    brain_view_tiled = 0;
    if ~exist('esp32WebsocketClient', 'var')
	    esp32WebsocketClient = 0;
    end
    spinled = 1;

    if ~exist('neuron_tones', 'var')
        neuron_tones = 0;
    end

    %% Record data
    if record_data
        if ispc
            rec_dir_name = strcat('Rec', num2str(nrecs + 1), '\');
        elseif ismac
            rec_dir_name = strcat('Rec', num2str(nrecs + 1), '/');
        end
        mkdir(strcat(dataset_dir_name, rec_dir_name))
        disp(horzcat('Created new recording directory: ', rec_dir_name))            
    end

    %% Visual features
    n_basic_vis_features = size(vis_pref_names, 2); % Clumsy hack, remove
    if use_cnn
        labels = readcell('alllabels.txt');
        object_ns = [47, 292, 418, 419, 441, 447, 479, 505, 527, 606, 621, 771, 847, 951, 955];
        object_strs = labels(object_ns);
        vis_pref_names = [vis_pref_names, object_strs'];
    elseif use_rcnn
        vis_pref_names = [vis_pref_names, 'person1', 'person2', 'person3', 'person4', 'person5'];    
        object_strs = {'person1', 'person2', 'person3', 'person4', 'person5'};        
    elseif use_controllers
        controller_prep_code
        vis_pref_names = [vis_pref_names, labels'];
    end
    n_vis_prefs = size(vis_pref_names, 2);


    %% Prep
    left_state = 1;
    right_state = 1;
    this_state = 1;
    left_score = 0;
    right_score = 0;
    this_score = 0;

    left_torque = 0;
    left_dir = 0;
    right_torque = 0;
    right_dir = 0;
    robot_moving = 0;
    base_weight = max_w;
    
    left_torque_mem = 0;
    right_torque_mem = 0;

    ltp_recency_th_in_steps = round(ltp_recency_th_in_sec / ms_per_step);
    speaker_selected = 0;
    vocal_buffer = 0;
    dist_pref_names = {'Short', 'Medium', 'Long'};
    n_dist_prefs = size(dist_pref_names, 2);
    load('brainim_xy')
    design_action = 0;
    network_colors(1, :) = [1 0.9 0.8];
    
    serial_data = [];
    sens_thresholds = [10 10 10 10 10 10 10 10 10 10 10 10 10 10 10];
    encoding_pattern = ones(size(sens_thresholds));
    
    pulse_led_flag_1 = 0;
    pulse_led_flag_2 = 0;
    pulse_led_flag_3 = 0;
    script_running = 0;
    script_step_count = 0;
    for nscript = 1:size(script_names, 2)
        script_strs(nscript).name = script_names{nscript};
    end
    efferent_copy = 0;
    r_torque = 0;
    l_torque = 0;
    object_scores = zeros(n_vis_prefs-n_basic_vis_features,1); % should not be hard-coded
    inhibition_col = [0.85 0.85 0.85];

    robot_xy = [0 0];
    rblob_xy = [0 0];
    gblob_xy = [0 0];

        
    %% Audio
    audx = 250;
    sound_spectrum = zeros(audx, nsteps_per_loop);
    fx = (0:audx-1)*16;
    this_audio = [];
    audio_out_fs = 0;
    speaker_tone = 0;
    
    if matlab_speaker_ctrl
        try
            speaker_fs = 16000;
            speaker_obj = audioDeviceWriter('SampleRate', speaker_fs, 'SupportVariableSizeInput', 1);   
        catch
            disp('Failed to initiate audioDeviceWriter. Setting matlab_speaker_ctrl to 0.')
            matlab_speaker_ctrl = 0;
        end
    end
    
    if vocal

        disp(horzcat(num2str(n_out_sounds), ' wavs found'))
        audio_out_names = [];
        audio_out_durations = [];
        audio_out_wavs = struct;  %% Need ability to save these for brains and add 
        audio_out_fs = zeros(n_out_sounds, 1);    
        
        for nsound = 1:n_out_sounds
            audio_out_names{nsound} = available_sounds(nsound).name(1:end-4);
            [audio_y,audio_fs] = audioread(horzcat(sounds_dir_name, available_sounds(nsound).name(1:end)));
            audio_out_durations = [audio_out_durations length(audio_y)/audio_fs];
            audio_out_wavs(nsound).y = audio_y;
            audio_out_fs(nsound) = audio_fs;
        end
        
        if supervocal
            for nsound = 1:n_vis_prefs
                this_word = char(vis_pref_names(nsound));
                audio_out_names{n_out_sounds + nsound} = this_word;

                this_wav_m = tts(this_word,'Microsoft David Desktop - English (United States)',[],16000);
                this_wav_f = tts(this_word,'Microsoft Zira Desktop - English (United States)',[],16000);
                if length(this_wav_m) > length(this_wav_f)
                    this_wav_m = this_wav_m(1:length(this_wav_f));
                else
                    this_wav_f = this_wav_f(1:length(this_wav_m));
                end
                this_wav = this_wav_f + this_wav_m;                
                
                audio_out_durations = [audio_out_durations length(this_wav)/16000];
                audio_out_wavs(n_out_sounds + nsound).y = this_wav;
                audio_out_fs(n_out_sounds + nsound) = 16000;        
            end

            % Add custom sound phrases to lists here?
        end
  
    else
        n_out_sounds = 0;
        audio_out_fs = 0;
        audio_out_names = 0;
    end
        
    if rak_only
        rak_cam.writeSerial('d:120;d:220;d:320;d:420;d:520;d:620;')
    elseif use_esp32
        esp32WebsocketClient.send('d:120;d:220;d:320;d:420;d:520;d:620;');
    end
    
    button_startup_complete.BackgroundColor = [0.94 0.78 0.62];
    drawnow
    
    % Nothing prevents overwriting an existing brain
    disp(horzcat('Brain name = ', brain_name))
    if use_cnn
        tic
        g_net = googlenet;
        net_input_size = g_net.Layers(1).InputSize(1:2);
        disp(horzcat('googlenet loaded in ', num2str(round(toc)), ' s'))
    elseif ~exist('net', 'var') && use_rcnn
        tic
        net_input_size = [227 227];
%         load('rcnn5heads') % <<<< COMMENTED OUT FOR COMPILATION
        disp(horzcat('rcnn loaded in ', num2str(round(toc)), ' s'))
    elseif use_rcnn
        net_input_size = [224 224];
    end
    
    button_startup_complete.BackgroundColor = [0.6 0.95 0.6];
    
    if ~camera_present || ~exist('rak_cam', 'var')
        camera_present = 0;
        large_frame = zeros(720, 1280, 3, 'uint8');          
    end
    if use_webcam && (rak_only || use_esp32)
        large_frame = zeros(720, 1280, 3, 'uint8');
        prev_ext_uframe = imresize(large_frame, [227 404]);
    end
    
    drawnow
    pause(1)
    clear fig_design
    
    
    %% Prepare
    
    life_timer = tic;
    
    if ~exist('rak_cam_h', 'var')
        rak_cam_h = 720;
        rak_cam_w = 1280;
    end
    left_cut = [1 rak_cam_h 1 rak_cam_h]; 
    right_cut = [1 rak_cam_h (rak_cam_w - rak_cam_h + 1) rak_cam_w];    
    
    left_yx = [length(left_cut(1):left_cut(2)) length(left_cut(3):left_cut(4))];
    right_yx = [length(right_cut(1):right_cut(2)) length(right_cut(3):right_cut(4))];
    large_frame = zeros(rak_cam_h, rak_cam_w, 3, 'uint8');
    left_eye_frame = large_frame(left_cut(1):left_cut(2), left_cut(3):left_cut(4), :);
    right_eye_frame = large_frame(right_cut(1):right_cut(2), right_cut(3):right_cut(4), :);
    prev_left_eye_frame = imresize(left_eye_frame, net_input_size);
    prev_right_eye_frame = imresize(right_eye_frame, net_input_size);
    left_uframe = prev_left_eye_frame;
    right_uframe = prev_right_eye_frame;

    if matlab_audio_rec
        mic_fs = 44100;
        if exist('mic_obj', 'var')
            clear mic_obj
        end
        try
            mic_obj = audioDeviceReader;
            mic_fs = mic_obj.SampleRate;
            mic_obj.SamplesPerFrame = round(mic_fs * pulse_period * 0.8);
            setup(mic_obj)
        catch
            disp('audioDeviceReader failed to initialize. Setting matlab_audio_rec to 0.')
            matlab_audio_rec = 0;
        end
    end
    
%     if use_speech2text
%         disp('Initiating Google speech-to-text engine...')
%         mic_fs = 16000; % rem
%         speechObject = speechClient('Google','languageCode','en-US');
%     end
    
    
    %% Initialize brain and Runtime figure
    draw_fig_runtime
    draw_brain
    
    
    %% Prepare 2
    run_button = 0;
    nstep = 0;
    vis_pref_vals = zeros(n_vis_prefs, 2);
    motor_command = zeros(1, 5);
    prev_motor_command = zeros(1, 5);
    this_distance = 4000;
    reward = 0;
    firing = [];
    manual_control = 0;
    nasal_color_discount = [linspace(2, 0, left_yx(2)); linspace(0, 2, left_yx(2))];
    
    step_times = zeros(nsteps_per_loop, 1) + 0.1;
    steps_since_last_spike = nan(nneurons, 1);
    
    xstep = 0;
    rak_fail = 0;
    
    if hd_camera
        fs = 32000;
    else
        fs = 8000;
    end
    
    audio_I = zeros(nneurons, 1);
    audio_empty_flag = 0;
    rak_fails = 0;
    if ~exist('rak_cam_h', 'var')
        rak_cam_h = 720;
        rak_cam_w = 1280; 
    end
    
    
    %% Create data and command log
    if save_data_and_commands
        this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
    
        data_file_name = strcat('./Data/', this_time, '-', brain_name, '.mat');
        data = struct;
        data.computer_name = computer_name;
        data.start_time = this_time;
    
        command_log_file_name = strcat('./Command/', this_time, '-', brain_name, '.mat');
        if exist('command_log', 'var')
            command_log.stop_event = 'other';
            save(command_log_file_name, 'command_log')
            clear command_log
        end
        command_log = struct;
        command_log.computer_name = computer_name;
        command_log.start_time = this_time;
        command_log.n = 1;
    end
    
    
    %% Create and launch Runtime timer
    if exist('rak_pulse', 'var') && isvalid(rak_pulse)
        stop(rak_pulse)
        pause(1)
        delete(rak_pulse)
    end
    
    runtime_pulse = timer('period', pulse_period, 'timerfcn', 'runtime_pulse_code;', ...
        'stopfcn', 'if fig_design.UserData == 10 && run_button ~= 3 runtime_stop_code; end', ...
        'executionmode', 'fixedrate');
    
    set(button_startup_complete, 'enable', 'on')
    button_startup_complete.BackgroundColor = [0.8 0.8 0.8];
    drawnow

    start(runtime_pulse)

else

    button_startup_complete.BackgroundColor = [1 0.25 0.25];
    set(button_startup_complete, 'enable', 'on')
    pause(0.75)
    button_startup_complete.BackgroundColor = [0.8 0.8 0.8];

end

