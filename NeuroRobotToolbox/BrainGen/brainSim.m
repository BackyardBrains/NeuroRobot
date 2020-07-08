function spike_log = brainSim(a, b, c, d, connectome, nsteps)

nneurons = size(a, 1);
spike_log = zeros(nneurons, nsteps);
v(:, 1) = -65 + 5 * randn(nneurons,1);
u = b .* v;

for nstep = 1:nsteps

    % Add input noise
    I = 5 * randn(nneurons, 1);       

    % Find spiking neurons
    fired_now = v >= 30;
    
    % Update spike log
    spike_log(fired_now, nstep) = 1;

    % Reset spiking v to c
    v(fired_now) = c(fired_now);

    % Adjust spiking u to d
    u(fired_now) = u(fired_now) + d(fired_now);

    % Add spiking synaptic weights to neuronal inputs
    I = I + sum(connectome(fired_now,:), 1)';

    % Update v
    v = v + 0.5 * (0.04 * v.^2 + 5 * v + 140 - u + I);
    v = v + 0.5 * (0.04 * v.^2 + 5 * v + 140 - u + I);

    % Update u
    u = u + a .* (b .* v - u);

    % Avoid nans
    v(isnan(v)) = c(isnan(v));

end