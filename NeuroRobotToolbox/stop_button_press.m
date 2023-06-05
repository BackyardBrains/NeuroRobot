
stop(pulse)
actual_period = pulse.AveragePeriod;
disp(horzcat('Intended speed = ', num2str(ms_per_step), ' ms/step'))
disp(horzcat('Actual speed = ', num2str(round(actual_period * 1000)), ' ms/step'))
if actual_period / intended_timer_period > 1.2
    disp('The simulation speed is significantly slower than realtime')
    disp('You should increase the value of the "ms_per_step" variable')
end
delete(pulse)
close(fig_2ns)

button_to_library.BackgroundColor = [0.8 0.8 0.8];
set(button_camera, 'enable', 'on')
set(button_startup_complete, 'enable', 'on')
set(button_to_library, 'enable', 'on')
set(button_to_sleep, 'enable', 'on')
set(button_to_quit, 'enable', 'on')
set(button_new_brain, 'enable', 'on')

