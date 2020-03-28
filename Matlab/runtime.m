

%% NEUROROBOT RUNTIME


clear presynaptic_neuron
clear postsynaptic_neuron
clear postsynaptic_contact
clear neuron_xys
clear spikes_step

if use_profile
    profile clear
    profile on
end

life_timer = tic;


%% Initialize brain and runtime GUI
load_or_initialize_brain
draw_fig_runtime
if brain_view_tiled
    draw_brain_multiview
else
    draw_brain
end


%% Prepare
run_button = 0;
nstep = 0;
vis_pref_vals = zeros(n_vis_prefs, 2);
motor_command = zeros(1, 5);
prev_motor_command = zeros(1, 5);
this_distance = 4000;
reward = 0;
distance_read = 0;
firing = [];
manual_control = 0;
nasal_color_discount = [linspace(2, 0, left_yx(2)); linspace(0, 2, left_yx(2))];
if hd_camera
    large_frame = zeros(1080, 1920, 3, 'uint8');
else
    large_frame = zeros(720, 1280, 3, 'uint8');
end

if ext_cam_id
    save_ext_cam = zeros(720, 1280, 3, ext_cam_nsteps, 'uint8');
    save_firing = zeros(nneurons, ext_cam_nsteps, 'logical');
    save_left_cam = zeros(left_yx(1), left_yx(2), 3, ext_cam_nsteps, 'uint8');
    save_right_cam = zeros(right_yx(1), right_yx(2), 3, ext_cam_nsteps, 'uint8');
    save_time = zeros(1, ext_cam_nsteps);
end
step_times = nan(nsteps_per_loop, 1);
steps_since_last_spike = nan(nneurons, 1);
if bluetooth_present
    bluetooth_flush
end
xstep = 0;
rak_fail = 0;
if use_profile
    profile clear
    profile on    
end
% audioMat = [];
audio_step = [];
audio_max_freq = 0;
max_amp = 0;
max_freq = 0;
audio_max_freq = 0;
pw = zeros(1, 1000); 
audio_I = zeros(nneurons, 1);
audio_empty_flag = 0;
rak_fails = 0;


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


%% Run
% if ~isempty(pit_start_time)
%     this_flag = 0;
%     disp('Waiting for pit recording start time')
%     while ~this_flag
%         this_clock = clock;
%         if this_clock(4) >= pit_start_time(1) && this_clock(5) >= pit_start_time(2)
%             this_flag = 1;
%             disp('Pit recording started')
%         else
%             pause(0.01)
%         end
%     end
% end
if exist('rak_pulse', 'var') && isvalid(rak_pulse)
    stop(rak_pulse)
    delete(rak_pulse)
    disp('Previos rak_pulse deleted')
end
disp('Creating runtime_pulse')
runtime_pulse = timer('period', pulse_period, 'timerfcn', 'runtime_pulse_code;', 'stopfcn', 'if fig_design.UserData == 10 && run_button ~= 3 runtime_stop_code; end', 'executionmode', 'fixedrate');
start(runtime_pulse)

