
stop(pulse)
actual_period = pulse.AveragePeriod;
disp(horzcat('Intended speed = ', num2str(ms_per_step), ' ms/step'))
disp(horzcat('Actual speed = ', num2str(round(actual_period * 1000)), ' ms/step'))
if actual_period / intended_timer_period > 1.2
    disp('The simulation speed is significantly slower than realtime')
    disp('You should increase the value of the "ms_per_step" variable')
end
delete(timerfind)
close(fig1)