
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
update_brain
draw_step
update_motors
left_eye_frame = large_frame(left_cut(1):left_cut(2), left_cut(3):left_cut(4), :);
right_eye_frame = large_frame(right_cut(1):right_cut(2), right_cut(3):right_cut(4), :);    
show_left_eye.CData = left_eye_frame;
show_right_eye.CData = right_eye_frame;
process_visual_input
process_audio_input
if bluetooth_present
    bluetooth_get_distance
end
if rak_only
    rak_get_serial
end
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
    disp('rak_cam is no longer running, stopping')
    stop(rak_pulse)
    pause(0.5)
    rak_fail = 1;
end
if run_button == 4 || rak_fail
    stop(runtime_pulse)
end
enter_design % if run_button = 1
drawnow
% Record data
if save_data_and_commands
    if nneurons
        rec_timer = tic;
        data.firing(:,xstep) = firing;
        data.connectome(:,:,xstep) = connectome;
        data.rec_time(xstep) = toc(rec_timer);
        data.timestamp(xstep) = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
    end
end
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
