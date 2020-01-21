
%% Start of pulse code
% disp('1')
nstep = nstep + 1;
xstep = xstep + 1;
step_timer = tic;
lifetime = toc(life_timer);
if lifetime == 5 * 60
    disp(horzcat('Lifetime = ', num2str(round(lifetime)), ' s'))
elseif lifetime == 5 * 60 && lifetime < 5 * 60 * 60
    disp(horzcat('Lifetime = ', num2str(round(lifetime/60)), ' min'))
elseif lifetime >= 5 * 60 * 60
    disp(horzcat('Lifetime = ', num2str(round(lifetime/60/60)), ' hrs'))
end

%% Update brain
% disp('2')
update_brain
draw_step

%% Update motors
% disp('3')
update_motors
left_eye_frame = large_frame(left_cut(1):left_cut(2), left_cut(3):left_cut(4), :);
right_eye_frame = large_frame(right_cut(1):right_cut(2), right_cut(3):right_cut(4), :);    
show_left_eye.CData = left_eye_frame;
show_right_eye.CData = right_eye_frame;

%% Process visual input
% disp('4')
process_visual_input

%% Process audio input
% disp('5')R
process_audio_input

%% Serial
% disp('6')
if bluetooth_present
    bluetooth_get_distance
end
if rak_only
    rak_get_serial
end

%% Interface
% disp('7')
if run_button == 2
    save_brain
end
enter_pause % if run_button == 3
enter_reward % if run_button == 5
update_ext_cam
if nstep == nsteps_per_loop
    nstep = 0;
    step_duration_in_ms = round(nanmedian(step_times * 1000));
    disp(horzcat('Step time = ', num2str(step_duration_in_ms), ' ms (pulse period = ', num2str(pulse_period * 1000), ' ms)'))
end
if ~use_webcam && rak_only && ~rak_cam.isRunning() % This screws with DIY no?
    rak_fails = rak_fails + 1;
    disp('rak_cam is not running (pulse code line 56)')
    if rak_fails > 30
        rak_fails = 0;
        disp('rak_cam is no longer running, stopping')
        stop(rak_pulse)
        pause(0.5)
        rak_fail = 1;
    end
end
if run_button == 4 || rak_fail
    stop(runtime_pulse)
end

%% Record data
% disp('8')
if save_data_and_commands
    if nneurons
        rec_timer = tic;
        data.firing(:,xstep) = firing;
        data.connectome(:,:,xstep) = connectome;
        data.rec_time(xstep) = toc(rec_timer);
        data.timestamp(xstep) = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
    end
end


%% End of pulse code
% disp('9')
enter_design % if run_button = 1
drawnow

% if ~isempty(pit_stop_time)
%     this_clock = clock;
%     if this_clock(4) >= pit_stop_time(1) && this_clock(5) >= pit_stop_time(2)
%         disp('Pit recording stop time')
%         disp('Pit recording stopped')
%         stop(runtime_pulse)
%     else
%         pause(0.01)
%     end
% end
try % This avoids error due to stop code deleting step_timer before it's called here
    step_times(nstep + 1) = toc(step_timer);
catch
end
if run_button == 6
    
    %% Make annotation
    make_annotation
    
    %% Return
    run_button = 0;
    
end
    
% disp(num2str(vis_pref_vals'))

%%%% CHECK FOR EXERCISE SUCCESS
if ~isempty(this_exercise)
    
    if srcmp(this_exercise, 'BetsyUp')
        if connectome(1,3)
            disp('You successfully completed exercise BetsyUP!')
            disp('You are the nth person ever to do this')
            keyboard
        end
    end
    
end
    
% if something then note exercise success
%     for example, a betsy with synapse 1-3>24 % make the 24 42