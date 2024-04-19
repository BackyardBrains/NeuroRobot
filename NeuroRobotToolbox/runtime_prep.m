
set(button_startup_complete, 'enable', 'off')
drawnow


%% Robot settings
update_robot_select


%% App settings
bg_colors = 1;
draw_neuron_numbers = 1;
draw_synapse_strengths = 1;

% 1 = 'Record Data'
if sum(select_app.Value == 1)
    record_data = 1;
else
    record_data = 0;
end

%% Trained Nets settings
% 1 = 'GoogLeNet'
if sum(select_nets.Value == 1)
    use_cnn = 1;
else
    use_cnn = 0;
end

% 2 = 'CustomRCNN'
if sum(select_nets.Value == 2)
    use_rcnn = 1;
else
    use_rcnn = 0;
end

% 3 = 'Custom net'
if sum(select_nets.Value > nimported)
    use_custom_net = 1;
else
    use_custom_net = 0;
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


%% Add path
% if ~isdeployed
%     addpath(genpath(".\MatlabWebSocket\"))
% end


%% Calibrate distance sensor
esp_get_serial
dist_short = 16;
dist_med = 21;
dist_long = 26;
scores = 0;


%%
this_key = 0;


%% Select brain
brain_name = brain_string{select_brain.Value};

load(strcat(brain_dir, brain_name, '.mat'))
load_brain

spikes_step = zeros(nneurons, ms_per_step);

brain_support = 1;
if ~isempty(trained_nets{1}) && sum(strcmp(trained_nets, 'GoogLeNet')) && ~use_cnn %% This needs a look to support new customrcnn
    brain_support = 0;
    disp(horzcat('Error: Brain needs GoogLeNet'))
end
% if length(trained_nets) > 1 && ~use_rcnn
% 
% 
% 
%     && isempty(trained_nets{2})
%     brain_support = 0;
%     disp(horzcat('Error: Brain needs ', trained_nets{2}))
% end

if exist('rak_only', 'var') && brain_support
    
    %% Clear timers - why is this used?
    if exist('runtime_pulse', 'var')
        try
            stop(runtime_pulse)
        catch
        end
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
    letters = {'-', 'A', 'B', 'C', 'D', 'E',...
        'F', 'G', 'H', 'I', 'J',...
        'K', 'L', 'M', 'N', 'O', ...
        'P', 'Q'};
    net_input_size = [224 224];
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
    vis_pref_names = basic_vis_pref_names;
    if use_cnn
        use_cnn_code
    end

    if use_rcnn
        load(horzcat(nets_dir_name, 'rcnn1'))
        this_label = 'robot';
        vis_pref_names = [basic_vis_pref_names, this_label];  
        n_vis_prefs = size(vis_pref_names, 2);
        if length(trained_nets) > 1
            trained_nets{2} = 'CustomRCNN';
        elseif length(trained_nets) == 1
            trained_nets{1} = 'CustomRCNN';
        end
    end

    if use_custom_net
        these_nets = option_nets(select_nets.Value);        
        this_ind = find(~strcmp(these_nets, 'GoogLeNet'));
        full_net_name = option_nets{select_nets.Value(this_ind)};        
        trained_nets{3} = full_net_name; %% Only supports one custom net

        cnet_temp = strfind(full_net_name, '---');
        if cnet_temp >= 1
            state_net_name = full_net_name(1:cnet_temp(1)-1);
            action_net_name = full_net_name(cnet_temp(1)+1:end);            
        else
            state_net_name = full_net_name;
            action_net_name = '';        
        end

        try
            load(strcat(nets_dir_name, state_net_name, '-ml')) %% state_net_name fix
            load(strcat(nets_dir_name, state_net_name, '-labels')) %% state_net_name fix
            regression_flag = 0;
            unique_states = unique(labels);
            n_unique_states = length(unique_states);
            vis_pref_names = [vis_pref_names, labels'];
        catch
            disp('Unable to load convnet / state net')
            % regression_flag = 1;
            % vis_pref_names = [vis_pref_names, 'scalar'];
        end
        
        if length(cnet_temp) >= 1
            % try    
                load(horzcat(nets_dir_name, state_net_name, '-', action_net_name, '-ml'))

                % openfig(strcat(nets_dir_name, state_net_name, '-examples.fig'))
                load(strcat(nets_dir_name, state_net_name, '-states'))
                load(strcat(nets_dir_name, state_net_name, '-torque_data'))
                load(strcat(nets_dir_name, state_net_name, '-actions'))
                load(strcat(nets_dir_name, state_net_name, '-tuples'))
                load(strcat(nets_dir_name, state_net_name, '-mdp'))
                
                n_unique_states = length(unique(states));
                n_unique_actions = length(unique(actions));
                ntuples = size(states, 1);
                disp(horzcat('loaded ntuples: ', num2str(ntuples)))               
                
                % ml_visualize_mdp
                ml_get_combs_quick
            % catch
                % disp('Unable to load agent / action net')
            % end
        end
    else
        state_net_name = '';
        action_net_name = '';
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
    base_weight = 25;
    
    left_torque_mem = 0;
    right_torque_mem = 0;

    ltp_recency_th_in_steps = round(ltp_recency_th_in_sec / ms_per_step);
    speaker_selected = 0;
    vocal_buffer = 0;
    dist_pref_names = {'Short', 'Medium', 'Long'};
    n_dist_prefs = size(dist_pref_names, 2);
    load('brainim_xy')
    design_action = 0;
    
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
    
    button_startup_complete.BackgroundColor = [0.6 0.95 0.6];
    
    if ~camera_present || ~exist('rak_cam', 'var')
        camera_present = 0;
        large_frame = zeros(720, 1280, 3, 'uint8');          
    end
    if use_webcam && (rak_only || use_esp32)
        ext_frame = zeros(ext_cam_h, ext_cam_w, 3, 'uint8');
        prev_ext_frame = ext_frame;
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
    
    % left_cut = [16 rak_cam_h - 30 1 rak_cam_h]; 
    % right_cut = [1 rak_cam_h (rak_cam_w - rak_cam_h + 1) rak_cam_w];    
    
    left_cut = [16 (rak_cam_h-30) 16 (rak_cam_h-30)];
    right_cut = [16 (rak_cam_h-30) (rak_cam_w-(rak_cam_h-30)+1) rak_cam_w] ;

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
        if exist('mic_obj', 'var')
            clear mic_obj
        end
        try
            mic_obj = audioDeviceReader;
            mic_fs = mic_obj.SampleRate;
%             release(mic_obj);
%             mic_obj.SampleRate = 32000;
            mic_obj.SamplesPerFrame = round(mic_fs * pulse_period * 0.8); % Too much? Blocking?
            setup(mic_obj)
        catch
            disp('audioDeviceReader failed to initialize. Setting matlab_audio_rec to 0.')
            matlab_audio_rec = 0;
            mic_fs = 44100;
        end
    else
        mic_fs = 44100;
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

