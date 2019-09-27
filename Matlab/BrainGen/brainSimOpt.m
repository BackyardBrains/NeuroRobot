function rx = brainSimOpt(this_in)

a = this_in(1, :)';
b = this_in(2, :)';
c = this_in(3, :)';
d = this_in(4, :)';
connectome = this_in(5:end, :)';

nsteps = 3000;
                
nneurons = length(a);
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

intended_activity = zeros(nsteps, 1);
x = exp(0.02:0.02:10);

for ii = 1:nsteps
    if ii <= 500
        intended_activity(ii) = x(ii);
    elseif ii <= 1000
        intended_activity(ii) = x(ii-500);
    elseif ii <= 1500
        intended_activity(ii) = x(ii-1000);
    elseif ii <= 2000
        intended_activity(ii) = x(ii-1500);
    elseif ii <= 2500
        intended_activity(ii) = x(ii-2000);
    elseif ii <= 3000
        intended_activity(ii) = x(ii-2500);
    end
end

intended_activity = intended_activity - min(intended_activity);
intended_activity = intended_activity / max(intended_activity);

if size(spike_log, 1) == nneurons
    mean_activity = mean(spike_log);
    mean_activity = mean_activity - min(mean_activity);
    mean_activity = mean_activity / max(mean_activity);
    if ~sum(isnan(mean_activity))
        r = corr(mean_activity', intended_activity);
    else
        error('NaN found')
    end

else
    r = 0;
end

rx = 1-r;