function [mean_activity, spike_log] = run_brain(a, b, c, d, connectome, nsteps)
nneurons = length(a);
spike_log = zeros(nneurons, nsteps);
v(:, 1) = -65 + 5 * randn(nneurons,1);
u = b .* v;
for nstep = 1:nsteps
    I = 5 * randn(nneurons, 1);       
    fired_now = v >= 30;
    spike_log(fired_now, nstep) = 1;
    v(fired_now) = c(fired_now);
    u(fired_now) = u(fired_now) + d(fired_now);
    I = I + sum(connectome(fired_now,:), 1)';
    v = v + 0.5 * (0.04 * v.^2 + 5 * v + 140 - u + I);
    v = v + 0.5 * (0.04 * v.^2 + 5 * v + 140 - u + I);
    u = u + a .* (b .* v - u);
    v(isnan(v)) = c(isnan(v));
end
mean_activity = mean(spike_log);
if sum(mean_activity)
    mean_activity = mean_activity - min(mean_activity);
    mean_activity = mean_activity / max(mean_activity);
end