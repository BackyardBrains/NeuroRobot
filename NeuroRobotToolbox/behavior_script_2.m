
% Random walk

% script_step_count = script_step_count + 1;
% 
% left_forward = left_forward + rand * 50;
% right_forward = right_forward + rand * 50;
% speaker_tone = 500 + cos(script_step_count) * 100;
% 
% if script_step_count > 30
%     script_running = 0;
%     script_step_count = 0;
% end

% just_kitten
% just_green

script_step_count = script_step_count + 1;

if script_step_count <= 20
%     left_forward = left_forward + (script_step_count * 2.5);
%     right_backward = right_backward + (script_step_count * 2.5);
%     speaker_tone = script_step_count * 200;
    just_green
elseif script_step_count > 20
%     left_forward = left_forward + (40 - script_step_count) * 2.5;
%     right_backward = right_backward + (40 - script_step_count) * 2.5; 
%     speaker_tone = (40 - script_step_count) * 200;
    just_off
end

if script_step_count > 40
    script_running = 0;
    script_step_count = 0;
end
