% Reset simulation parameters
nstep = 1;
v = c + 5 * randn(nneurons, 1);
u = b .* v;
spikes_loop = zeros(size(spikes_loop));
run_button = 0;
% Initialize GUI
draw_fig_runtime
draw_brain
start(runtime_pulse)