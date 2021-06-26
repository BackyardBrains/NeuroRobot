
% Red

script_step_count = script_step_count + 1;

if script_step_count <= 20
    just_red
elseif script_step_count > 20
    just_off
end

if script_step_count > 40
    script_running = 0;
    script_step_count = 0;
end
