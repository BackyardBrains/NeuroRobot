
% rak_cam.sendAudio('Sounds/monkey.mp3');

rhythmx = (10^-5);

disp(horzcat('monkey_base = ', num2str(monkey_base), ', monkey_superflag = ', num2str(monkey_superflag), ', monkey_flag = ', num2str(monkey_flag)))

if monkey_base > rhythmx
    if ~monkey_superflag
        monkey_superflag = 10;
        monkey_done = 0;
    end
end

if monkey_superflag > 1
    monkey_superflag = monkey_superflag - 1;
end

if monkey_superflag == 1 && monkey_base < rhythmx
    monkey_superflag = 0;
    monkey_flag = 0;
    monkey_done = 0;
    disp('Ready')
    just_off
    pause(0.1)
elseif monkey_superflag == 1 && monkey_base > rhythmx
    disp('Waiting')
    just_off
    pause(0.1)
end

if monkey_superflag > 1 && ~monkey_done
    if ~exist('monkey_shake', 'var')
        monkey_shake = 'left';
    end
    if strcmp(monkey_shake, 'left')
        if ~monkey_flag
            monkey_flag = 5;
        end
        if monkey_flag
            monkey_flag = monkey_flag - 1;
%             left_backward = 100;
%             right_forward = 100;
            disp(horzcat('Go ', monkey_shake))
            just_red
            pause(0.1)
        end
        if monkey_flag == 1
            monkey_shake = 'right';
            monkey_done = 1;
            just_off
            pause(0.1)            
        end
    elseif strcmp(monkey_shake, 'right')
        if ~monkey_flag
            monkey_flag = 5;
        end
        if monkey_flag
            monkey_flag = monkey_flag - 1;
%             left_forward = 100;
%             right_backward = 100;
            disp(horzcat('Go ', monkey_shake))
            just_green
            pause(0.1)
        end
        if monkey_flag == 1
            monkey_shake = 'left';
            monkey_done = 1;
            just_off
            pause(0.1)
        end            
    end
end
    
if monkey_superflag == 0
    just_off
    pause(0.1)
end
