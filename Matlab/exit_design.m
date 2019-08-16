% Reset simulation parameters
nstep = 1;
v = c + 5 * randn(nneurons, 1);
u = b .* v;
spikes_loop = zeros(size(spikes_loop));
run_button = 0;

% Command log
if save_data_and_commands
    this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
    command_log.entry(command_log.n).time = this_time;    
    command_log.entry(command_log.n).action = 'exit design';
    command_log.n = command_log.n + 1;
end

% Initialize GUI
draw_fig_runtime
draw_brain
start(runtime_pulse)