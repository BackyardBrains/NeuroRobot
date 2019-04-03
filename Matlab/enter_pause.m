if run_button == 3
%     button_pause.String = 'Start brain';
%     button_pause.BackgroundColor = [1 0.6 0.2];
run_button = 4;
voluntary_restart = 1;
%     if bluetooth_present
%         motor_command = [0 0 0 0 0];
%         prev_motor_command = [0 0 0 0 0];
%         bluetooth_send_motor_command
%     end
%     stop(runtime_pulse)
end   