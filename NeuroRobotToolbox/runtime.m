

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

% if save_for_hippocampus
%     this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
%     sound_in_file_name = strcat('./Hippocampus/', brain_name, '-', this_time, '.xlsx');    
%     writematrix([], sound_in_file_name, 'FileType', 'spreadsheet')
% end

multi_neuron_opt = 0;

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

