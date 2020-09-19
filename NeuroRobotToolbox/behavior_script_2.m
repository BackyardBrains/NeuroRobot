%%%% 'Random walk'

%%%% SCRIPT 2 %%%%

% This will be executed once per step (step time usually 100 ms)

script_step_count = script_step_count + 1;

left_forward = left_forward + rand * 50;
right_forward = right_forward + rand * 50;
speaker_tone = 500 + cos(script_step_count) * 100;

if script_step_count > 30
    script_running = 0;
    script_step_count = 0;
end

