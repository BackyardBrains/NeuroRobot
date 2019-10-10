function r = brainSim2(x)

nneurons = 100;
xx = reshape(x, [nneurons + 4, nneurons]);

nsteps = 3000;
nneurons = size(xx, 2);

a = xx(1,:)';
b = xx(2,:)';
c = xx(3,:)';
d = xx(4,:)';
for nneuron = 1:nneurons
    connectome(nneuron,:) = xx(4+nneuron,:);
end
 
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
this_exp = exp(0.02:0.02:10);

for ii = 1:nsteps
    if ii <= 500
        intended_activity(ii) = this_exp(ii);
    elseif ii <= 1000
        intended_activity(ii) = this_exp(ii-500);
    elseif ii <= 1500
        intended_activity(ii) = this_exp(ii-1000);
    elseif ii <= 2000
        intended_activity(ii) = this_exp(ii-1500);
    elseif ii <= 2500
        intended_activity(ii) = this_exp(ii-2000);
    elseif ii <= 3000
        intended_activity(ii) = this_exp(ii-2500);
    end
end

intended_activity = intended_activity - min(intended_activity);
intended_activity = intended_activity / max(intended_activity);


mean_activity = mean(spike_log);
if sum(mean_activity)
    mean_activity = mean_activity - min(mean_activity);
    mean_activity = mean_activity / max(mean_activity);
end
% r = corr(mean_activity', intended_activity);
r = sum(abs(mean_activity' - intended_activity));

if isnan(r)
    r = Inf;
end

