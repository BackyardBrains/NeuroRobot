
%% Log lifetime
lifetime = toc(life_timer);
disp(horzcat('Lifetime = ', num2str(round(lifetime/60)), ' min'))


%% Stop and reset motors
if rak_only
    rak_cam.writeSerial('l:0')
    pause(0.01)
    rak_cam.writeSerial('r:0')
    pause(0.01)
elseif bluetooth_present
    motor_command = [0 0 0 0 0];
    prev_motor_command = [0 0 0 0 0];
    bluetooth_send_motor_command
end


%% Save brain figure
if ~restarting && save_brain_jpg
    fig_print = figure(3);
    set(fig_print, 'position', [400 100 1000 800]);
    brain_ax = axes('position', [0 0 1 1]);
    image('CData',im2,'XData',[-3 3],'YData',[-3 3])
    set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
    axis([-3 3 -3 3])
    hold on
    draw_brain
    export_fig(fig_print, horzcat('.\Brains\', brain_name, '-', date), '-r150', '-jpg', '-nocrop')
    close(fig_print)
end


%% Store analysis code
if in_analysis
    bdata(:,in_analysis) = adata;
    in_analysis = in_analysis + 1;
    if in_analysis <= length(avals)
        restarting = 1;
    else
        restarting = 0;
        in_analysis = 0;
    end
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
    restarting = 1;
    restarts = restarts + 1;
end

if voluntary_restart
    restarting = 1;
end

%% Return to startup
neurorobot

