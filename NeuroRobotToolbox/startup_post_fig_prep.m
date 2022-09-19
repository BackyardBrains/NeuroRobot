



read_settings


%% Clear timers - why is this used?
if exist('runtime_pulse', 'var')
    delete(runtime_pulse)
end
clear step_timer
clear life_timer
disp('---------')


%% Prepare
computer_name = getenv('COMPUTERNAME');
user_name = getenv('USERNAME');
microcircuit = 0;           % Use smaller neurons and synapses, no neuron numbers (AUTOMATIC?)
stop_step = 0;
ext_cam_id = 0;
ext_cam_nsteps = 100; % check this
nsteps_per_loop = 100;
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

ms_per_step = round(pulse_period * 1000);
ltp_recency_th_in_steps = round(ltp_recency_th_in_sec / ms_per_step);
speaker_selected = 0;
if ~exist('voluntary_restart', 'var')
    voluntary_restart = 0;
end
vocal_buffer = 0;
im = flipud(255 - ((255 - imread(this_workspace_fig))));
im2 = flipud(255 - ((255 - imread(this_workspace_fig))));
contact_xys = [-1.2, 2.05; 1.2, 2.1; -2.08, -0.38; 2.14, -0.38; ...
    -0.05, 2.45; -1.9, 1.45; -1.9, 0.95; -1.9, -1.78; ...
    -1.9, -2.28; 1.92, 1.49; 1.92, 0.95; 1.92, -1.82; 1.92, -2.29];
ncontacts = size(contact_xys, 1);
dist_pref_names = {'Short', 'Medium', 'Long'};
n_dist_prefs = size(dist_pref_names, 2);
load('brainim_xy')
design_action = 0;
network_colors(1, :) = [1 0.9 0.8];
vis_pref_names = {'Red', 'red-temp', 'Green', 'green-temp', 'Blue', 'blue-temp', 'Movement'};
n_basic_vis_features = length(vis_pref_names);
serial_data = [];

if use_cnn
    labels = readcell('alllabels.txt');
    object_ns = [47, 292, 418, 419, 441, 447, 479, 505, 527, 606, 621, 771, 847, 951, 955];
    object_strs = labels(object_ns);
    vis_pref_names = [vis_pref_names, object_strs'];
    score = zeros(1, 1000);
elseif use_rcnn
    vis_pref_names = [vis_pref_names, 'ariyana', 'head', 'nour', 'sarah', 'wenbo'];    
    object_strs = {'ariyana', 'head', 'nour', 'sarah', 'wenbo'};
end
n_vis_prefs = size(vis_pref_names, 2);
sens_thresholds = [10 10 10 10 10 10 10 10 10 10 10 10 10 10 10];
encoding_pattern = ones(size(sens_thresholds));
if ~exist('restarting', 'var')
    restarting = 0;
end
if ~exist('restarts', 'var')
    restarts = 0;
end
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
%         labels = folders2labels(strcat(data_dir_name, 'Classifier\'));
        load(strcat(data_dir_name, 'labels'))
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
        load(strcat(data_dir_name, 'randomwalk_net'))
        load(strcat(data_dir_name, 'AgentHeliomax'))        
    elseif use_controllers == 2
        load(strcat(data_dir_name, 'randomwalk_net'))
        load(strcat(data_dir_name, 'DeepAgentHeliomax'))
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