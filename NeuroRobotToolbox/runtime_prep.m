
if exist('rak_only', 'var')

    %% Get settings
    % option_app = {'BG Color Scheme', 'Draw Neuron Numbers'; 'Draw Synapse Weights', 'Record Data', 'Use RL Controllers};
    if sum(select_app.Value == 1)
        bg_colors = 1;              % Use neuron color to indicate network ID, and neuron flickering to indicate spikes  
    else
        bg_colors = 0;
    end
    
    if sum(select_app.Value == 2)
        draw_neuron_numbers = 1;
    else
        draw_neuron_numbers = 0;
    end
    
    if sum(select_app.Value == 3)
        draw_synapse_strengths = 1;
    else
        draw_synapse_strengths = 0;
    end
    
    
    if sum(select_app.Value == 4)
        save_experiences = 1;
    else
        save_experiences = 0;
    end
    
    if sum(select_app.Value == 5)
        use_controllers = 2;        % Switch this so correct nets are loaded with brain selection    
    else
        use_controllers = 0;
    end
    
    % option_vision = {'RandomWalk'; 'AlexNet'; 'Robots'; 'Faces'};
    if sum(select_vision.Value == 1)    
    end
    if sum(select_vision.Value == 2)
        use_cnn = 1;
    else
        use_cnn = 0;
    end
    if sum(select_vision.Value == 3)
        use_rcnn = 1;
    else
        use_rcnn = 0;
    end
    if sum(select_vision.Value == 4)
    end
    
    % option_hearing = {'Microphone/FFT', 'Speech2Text', 'Text2Speech'; 'OpenAI'};
    audio_th = 1;             % Audio threshold (increase if sound spectrum looks too crowded)
    matlab_audio_rec = 1;       % Use computer microphone to listen
    matlab_speaker_ctrl = 0;    % Multi tone output
    vocal = 0;                  % Custom sound output
    supervocal = 0;             % Custom word output (text-to-speech - REQUIRES WINDOWS)
    
    if sum(select_communication.Value == 1)
    else
    end
    if sum(select_communication.Value == 2)
    else
    end
    if sum(select_communication.Value == 3)
    else
    end
    if sum(select_communication.Value == 4)
    else
    end
    
    % select_brain
    brain_name = brain_string{select_brain.Value};
    
    
    %% Clear timers - why is this used?
    if exist('runtime_pulse', 'var')
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
    stop_step = 0;
    ext_cam_id = 0;
    ext_cam_nsteps = 100; % check this
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
    vis_prefs = [];
    neuron_scripts = [];
    if ~exist('neuron_tones', 'var')
        neuron_tones = 0;
    end
    
    left_torque = 0;
    left_dir = 0;
    right_torque = 0;
    right_dir = 0;
    robot_moving = 0;
    base_weight = max_w;
    
    ltp_recency_th_in_steps = round(ltp_recency_th_in_sec / ms_per_step);
    speaker_selected = 0;
    vocal_buffer = 0;
    dist_pref_names = {'Short', 'Medium', 'Long'};
    n_dist_prefs = size(dist_pref_names, 2);
    load('brainim_xy')
    design_action = 0;
    network_colors(1, :) = [1 0.9 0.8];
    
    n_basic_vis_features = length(vis_pref_names);
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
    
    if save_experiences || use_controllers || dev_mode
        
        left_torque_mem = 0;
        right_torque_mem = 0;
    
        if use_controllers
    
            tuples = zeros(stop_step, 6);
            
            load(strcat(data_dir_name, 'livingroom_labels'))
            unique_states = unique(labels);
            n_unique_states = length(unique_states);

            load(strcat(data_dir_name, 'torque_data'))
            load(strcat(data_dir_name, 'actions'))
            n_unique_actions = length(unique(actions));
            motor_combs = zeros(n_unique_actions, 2);
            for naction = 1:n_unique_actions
                motor_combs(naction, :) = mean(torque_data(actions == naction, :), 1);
            end
    
        end
    
        if use_controllers == 1
            load(strcat(data_dir_name, 'livingroom_net'))
            load(strcat(data_dir_name, 'AgentTV'))        
        elseif use_controllers == 2
            load(strcat(data_dir_name, 'livingroom_net'))
            load(strcat(data_dir_name, 'DeepAgentTV'))
        end
    end
    
    
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
        available_sounds = dir('./Sounds/*.mp3');
        n_out_sounds = size(available_sounds, 1);
        audio_out_names = [];
        audio_out_durations = [];
        audio_out_wavs = struct;  %% Need ability to save these for brains and add 
        audio_out_fs = zeros(n_out_sounds, 1);    
        
        for nsound = 1:n_out_sounds
            audio_out_names{nsound} = available_sounds(nsound).name(1:end-4);
            [audio_y,audio_fs] = audioread(horzcat('./Sounds/', available_sounds(nsound).name));
            audio_out_durations = [audio_out_durations length(audio_y)/audio_fs];
            audio_out_wavs(nsound).y = audio_y;
            audio_out_fs(nsound) = audio_fs;
        end
        
        if supervocal
            for nsound = 1:n_vis_prefs
                this_word = vis_pref_names{nsound};
                audio_out_names{n_out_sounds + nsound} = this_word;
                this_wav = tts(this_word,'Microsoft David Desktop - English (United States)',[],16000);
        %         this_wav = tts(this_word,'Microsoft Zira Desktop - English (United States)',[],16000);
                this_wav = this_wav(find(this_wav,1,'first'):find(this_wav,1,'last'));
                audio_out_durations = [audio_out_durations length(this_wav)/16000];
                audio_out_wavs(n_out_sounds + nsound).y = this_wav;
                audio_out_fs(n_out_sounds + nsound) = 16000;        
            end
        end
    
    else
        n_out_sounds = 0;
        audio_out_fs = 0;
        audio_out_names = 0;
    end
    
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
        g_net = googlenet; %%% <<<<< Commented out for packaging
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
    
    
    %% Clear
    clear presynaptic_neuron
    clear postsynaptic_neuron
    clear postsynaptic_contact
    clear neuron_xys
    clear spikes_step
    
    
    %% Prepare
    % if use_profile
    %     profile clear
    %     profile on
    % end
    
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
    
    if dev_mode
        brainless_prepare
    end
    
    if matlab_audio_rec
        mic_fs = 16000;
        if exist('mic_obj', 'var')
            clear mic_obj
        end
        try
            mic_obj = audioDeviceReader('SampleRate',mic_fs,'SamplesPerFrame',(mic_fs*0.1)*0.8); % ms per step should come in here
            setup(mic_obj)
        catch
            disp('audioDeviceReader failed to initialize. Setting matlab_audio_rec to 0.')
            matlab_audio_rec = 0;
        end
    end
    
    if use_speech2text
        disp('Initiating Google speech-to-text engine...')
        mic_fs = 16000; % rem
        speechObject = speechClient('Google','languageCode','en-US');
    end
    
    
    %% Initialize brain and Runtime figure
    load_brain
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
    
    if ext_cam_id
        save_ext_cam = zeros(720, 1280, 3, ext_cam_nsteps, 'uint8');
        save_firing = zeros(nneurons, ext_cam_nsteps, 'logical');
        save_left_cam = zeros(left_yx(1), left_yx(2), 3, ext_cam_nsteps, 'uint8');
        save_right_cam = zeros(right_yx(1), right_yx(2), 3, ext_cam_nsteps, 'uint8');
        save_time = zeros(1, ext_cam_nsteps);
    end
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
    
    if supervocal && isfield(brain, 'audio_out_wavs')
        n_also_these = size(brain.audio_out_wavs, 2);
        if n_also_these > (n_out_sounds + n_vis_prefs)
            for n_also_this = n_out_sounds + n_vis_prefs +1:n_also_these
                audio_out_wavs(n_also_this).y = brain.audio_out_wavs(n_also_this).y;
                audio_out_fs(n_also_this, 1) = 16000;
                audio_out_names{n_also_this} = brain.audio_out_names{n_also_this};
                audio_out_durations = [audio_out_durations length(audio_out_wavs(n_also_this).y)/audio_out_fs(n_also_this)];
            end
        end
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
        delete(rak_pulse)
    end
    pause(1)
    
    runtime_pulse = timer('period', pulse_period, 'timerfcn', 'runtime_pulse_code;', ...
        'stopfcn', 'if fig_design.UserData == 10 && run_button ~= 3 runtime_stop_code; end', ...
        'executionmode', 'fixedrate');
    
    start(runtime_pulse)

else

    button_startup_complete.BackgroundColor = [1 0.25 0.25];
    pause(0.75)
    button_startup_complete.BackgroundColor = [0.8 0.8 0.8];

end