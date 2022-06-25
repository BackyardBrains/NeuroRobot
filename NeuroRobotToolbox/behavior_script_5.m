
% Random walk RL

script_step_count = script_step_count + 1;

disp(strcat('xstep: ', num2str(xstep)))

left_state = classify(net, imresize(left_uframe, [50 50]));
disp(horzcat('left state: ', char(left_state)))

right_state = classify(net, imresize(right_uframe, [50 50]));
disp(horzcat('right state: ', char(right_state)))

this_action = randsample(nactions, 1);
disp(horzcat('action: ', num2str(this_action)))

this_motor_vector = motor_combs(this_action, :);

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




