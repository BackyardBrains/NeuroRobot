
rhythmx = 10^-5;

disp(horzcat('monkey_base = ', num2str(monkey_base), ', monkey_superflag = ', num2str(monkey_superflag), ', monkey_flag = ', num2str(monkey_flag)))

if monkey_base > rhythmx
    if ~monkey_superflag
        monkey_superflag = 5;
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
elseif monkey_superflag == 1 && monkey_base > rhythmx
    disp('Waiting')
    just_off
end

if monkey_superflag > 1 && ~monkey_done
    if ~exist('monkey_shake', 'var')
        monkey_shake = 'left';
    end
    if ~monkey_flag
        monkey_flag = 3;
    end
    monkey_flag = monkey_flag - 1;
    disp(horzcat('Go ', monkey_shake))
    pause(0.1)
    if strcmp(monkey_shake, 'left')
        left_backward = 100;
        right_forward = 100;
        rak_cam.writeSerial('d:131;d:231;d:331;d:431;d:531;d:631;') % red
    elseif strcmp(monkey_shake, 'right')
        left_forward = 100;
        right_backward = 100;
        rak_cam.writeSerial('d:121;d:221;d:321;d:421;d:521;d:621;') % green
    elseif strcmp(monkey_shake, 'forward')
        left_forward = 100;
        right_forward = 100;
        rak_cam.writeSerial('d:111;d:211;d:311;d:411;d:511;d:611;') % blue
    elseif strcmp(monkey_shake, 'backward')
        left_backward = 100;
        right_backward = 100;
        rak_cam.writeSerial('d:111;d:211;d:311;d:411;d:511;d:611;') % blue
    end    
    if monkey_flag == 1
        if strcmp(monkey_shake, 'left')
            if rand < 0.9
                monkey_shake = 'right';
            else
                monkey_shake = 'forward';
            end
        elseif strcmp(monkey_shake, 'right')
            if rand < 0.9
                monkey_shake = 'left';
            else
                monkey_shake = 'backward';
            end
        elseif strcmp(monkey_shake, 'forward')
            if rand < 0.9
                monkey_shake = 'backward';
            else
                monkey_shake = 'left';
            end
        elseif strcmp(monkey_shake, 'backward')
            if rand < 0.9
                monkey_shake = 'forward';
            else
                monkey_shake = 'right';
            end
        end          
        monkey_done = 1;
        just_off            
    end
end
if monkey_superflag == 0
    just_off
end
