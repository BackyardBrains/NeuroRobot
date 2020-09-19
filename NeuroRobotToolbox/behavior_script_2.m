%%%% 'Random walk'

%%%% SCRIPT 2 %%%%

% This will be executed once per step (step time usually 100 ms)

script_step_count = script_step_count + 1;

% if script_step_count <= 20
%     left_backward = left_backward + (script_step_count * 2.5);
%     right_forward = right_forward + (script_step_count * 2.5);
%     speaker_tone = script_step_count * 200;
% elseif script_step_count > 20
%     left_backward = left_backward + (40 - script_step_count) * 2.5;
%     right_forward = right_forward + (40 - script_step_count) * 2.5; 
%     speaker_tone = (40 - script_step_count) * 200;
% end

left_forward = left_forward + rand * 50;
right_forward = right_forward + rand * 50;
speaker_tone = 500 + cos(script_step_count) * 100;


if script_step_count > 40
    script_running = 0;
    script_step_count = 0;
end

