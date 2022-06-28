
% Random walk RL

script_step_count = script_step_count + 1;
this_action = randsample(nactions, 1);
this_motor_vector = motor_combs(this_action, :);

disp(strcat('xstep: ', num2str(xstep)))
disp(horzcat('action: ', num2str(this_action)))
disp(horzcat('torques: ', num2str(this_motor_vector(1)), ' ', num2str(this_motor_vector(2))))

if this_motor_vector(1) > 0
    left_forward = this_motor_vector(1);
else
    left_backward = -this_motor_vector(1);
end

if this_motor_vector(2) > 0
    right_forward = this_motor_vector(2);
else
    right_backward = -this_motor_vector(2);
end
