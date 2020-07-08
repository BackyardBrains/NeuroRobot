function this_error = brainSim2(brain_vector)

get_nneurons
get_intended_activity

%% Unpack brain
brain = reshape(brain_vector, [nneurons + 4, nneurons]);
a = brain(1,:)';
b = brain(2,:)';
c = brain(3,:)';
d = brain(4,:)';
for nneuron = 1:nneurons
    connectome(nneuron,:) = brain(4+nneuron,:);
end

%% Simulate brain
nsteps = 3000; % Ditto
mean_errors = zeros(5, 1);
for nsim = 1:5
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

    %% Get mean activity
    mean_activity = mean(spike_log);
    mean_activity(1:50) = mean(mean_activity);
    if sum(mean_activity)
        mean_activity = mean_activity - min(mean_activity);
        mean_activity = mean_activity / max(mean_activity);
    end
    
    %% Get error
    this_error = sum(abs(mean_activity - intended_activity));  
    if isnan(this_error)
        this_error = nsteps^2;
    end
    mean_errors(nsim) = this_error;
    
end
this_error = mean(mean_errors);



