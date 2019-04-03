

%% Prepare
nstep = nstep + 1;
v_step = zeros(nneurons, ms_per_step);
spikes_step = zeros(nneurons, ms_per_step);
a = [fig1.UserData(1) fig1.UserData(7)]';
b = [fig1.UserData(2) fig1.UserData(8)]';
c = [fig1.UserData(3) fig1.UserData(9)]';
d = [fig1.UserData(4) fig1.UserData(10)]';
i_noise = [fig1.UserData(5) fig1.UserData(11)]';
connectome(1,2) = fig1.UserData(6);
connectome(2,1) = fig1.UserData(12);


%% Run one brain simulation step
for t = 1:ms_per_step

    % Add input noise
    I = i_noise .* randn(nneurons, 1); 

    % Find spiking neurons
    fired_now = v >= 30;
    spikes_step(fired_now, t) = 1;
    v_step(:, t) = v;

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


%% Plot
firing = sum(spikes_step, 2) > 0;
draw_neuron_core.CData = [1 - firing 1 - (firing * 0.25) 1 - firing] .* neuron_cols;
draw_neuron_edge.CData = [zeros(nneurons, 1) firing * 0.5 zeros(nneurons, 1)] .* neuron_cols;

v_traces(:, 1 + (nstep - 1) * ms_per_step : nstep * ms_per_step) = v_step;
v_traces(v_traces > 30) = 30;
vplot1.YData = v_traces(1,:) + 130;
vplot2.YData = v_traces(2,:);
vplot_front.XData = [nstep nstep] * ms_per_step;

drawnow
if nstep >= steps_per_loop
    nstep = 0;
end

