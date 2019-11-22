
%% Log lifetime
lifetime = toc(life_timer);
disp(horzcat('Lifetime = ', num2str(round(lifetime/60)), ' min'))


%% Stop and reset motors
if rak_only
    try
        rak_cam.writeSerial('l:0;r:0;s:0;')
    catch
        disp('Unable to stop and reset motors')
    end
elseif bluetooth_present
    motor_command = [0 0 0 0 0];
    prev_motor_command = [0 0 0 0 0];
    bluetooth_send_motor_command
end


%% Save brain figure
if ~restarting && save_brain_jpg
    print_brain
end


%% Save data and command log
if save_data_and_commands
    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
    data.stop_time  = this_time;
    data.brain = brain;
%     data.audio = audioMat;
    data.audio_step = audio_step;
    data.xstep = xstep;
    save(data_file_name, 'data')

    if run_button == 4 
        command_log.stop_event = 'stop button';
    elseif rak_fail
        command_log.stop_event = 'rak fail';
    end
    command_log.stop_time = this_time;
    save(command_log_file_name, 'command_log')
    clear command_log
end


%% End runtime
close(fig_design)
button_startup_complete.BackgroundColor = [0.8 0.8 0.8];
step_duration_in_ms = round(nanmedian(step_times * 1000));
disp(horzcat('Step time = ', num2str(step_duration_in_ms), ' ms'))
disp('Run complete')

if use_profile
    profile off
    profile viewer
end

if rak_fail
    disp('RAK connection lost')
    sound(gong, Fs * 7)
    pause(0.5)
%     restarting = 1;
end

if voluntary_restart
    restarting = 1;
end

% if evodevo
%     
%     % Initialize global optimizer
%     % Use current brain as starting point
%     % Somehow take reward into account such that optimization tends toward
%     % reward
%     % Generate new brain, possibly replacing current brain, possibly as
%     % offspring
%     
% end


%% Return to startup
if restarting && ~voluntary_restart
%     system_restart
    save('brain_name', 'brain_name')
    neurorobot
else
    neurorobot
end


