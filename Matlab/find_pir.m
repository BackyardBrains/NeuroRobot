

% Find PIR in Izhikevich space



clear

presynaptic = 1:5;
postsynaptic = 6:10;

duration_in_ms = 10000;
stim_times_in_ms = 3000;

nneurons = length([presynaptic postsynaptic]);
a = zeros(nneurons, 1);
b = zeros(nneurons, 1);
c = zeros(nneurons, 1);
d = zeros(nneurons, 1);
vis_prefs = zeros(nneurons, 23, 2);
dist_prefs = zeros(nneurons, 1);
connectome = zeros(nneurons, nneurons);
vis_pref_vals = zeros(6, 2);
this_distance = 300;


%% Build brain
for nneuron = 1:nneurons
    
    %% Izhikevich dimensions
    a(presynaptic, 1) = 0.02;
    b(presynaptic, 1) = 0.1;
    c(presynaptic, 1) = -65;
    d(presynaptic, 1) = 2;
    
    a(postsynaptic, 1) = 0.02;
    b(postsynaptic, 1) = 0.1;
    c(postsynaptic, 1) = -65;
    d(postsynaptic, 1) = 2;    
    
    %% Connectome
    for nneuron2 = 1:nneurons
        if sum(nneuron == presynaptic) && sum(nneuron2 == presynaptic)
            connectome(nneuron, nneuron2) = 37;
        end
    end
    
    %% Connectome
    for nneuron2 = 1:nneurons
        if sum(nneuron == presynaptic) && sum(nneuron2 == postsynaptic)
            connectome(nneuron, nneuron2) = 5;
        end
    end
    
    %% Connectome
    for nneuron2 = 1:nneurons
        if sum(nneuron == postsynaptic) && sum(nneuron2 == postsynaptic)
            connectome(nneuron, nneuron2) = 37;
        end
    end
    
    %% Connectome
    for nneuron2 = 1:nneurons
        if sum(nneuron == postsynaptic) && sum(nneuron2 == presynaptic)
            connectome(nneuron, nneuron2) = 5;
        end
    end    
end

v = c + 5 * randn(nneurons, 1);
u = b .* v;


%% Figure
spikes_step = zeros(nneurons, duration_in_ms);
v_step = zeros(nneurons, duration_in_ms);

fig = figure(1);
clf
ax_frame = axes('position', [0.02 0.1 0.96 0.88]);
% show_frame = imagesc(spikes_step, [0 1]);
show_frame = imagesc(v_step, [-100 100]);
set(gca, 'ytick', [])


%% Simulate
spikes_step = zeros(nneurons, duration_in_ms);
I_step = zeros(nneurons, duration_in_ms);

% Calculate visual input current
vis_I = zeros(nneurons, 1);
for nneuron = 1:nneurons % ugly for loop, fix this
    for ncam = 1:2
        these_prefs = logical(vis_prefs(nneuron, :, ncam));
        vis_I(nneuron) = vis_I(nneuron) + sum(vis_pref_vals(these_prefs, ncam));
    end
end 

% Calculate distance sensor input current
dist_I = zeros(nneurons, 1);  


% Run brain simulation
for t = 1:duration_in_ms

    % Add noise
    I = 5 * randn(nneurons, 1); 
    
    % Add stimulus
    if sum(t == stim_times_in_ms)
        I(presynaptic) = I(presynaptic) + 50;
    end

     % Find spiking neurons
    fired_now = v >= 30;
    spikes_step(fired_now, t) = 1;

    % Reset spiking v to c
    v(fired_now) = c(fired_now);

    % Adjust spiking u to d
    u(fired_now) = u(fired_now) + d(fired_now);

    % Add spiking synaptic weights to neuronal inputs
    I = I + sum(connectome(fired_now,:), 1)';

    % Add sensory input currents
    I = I + vis_I + dist_I;
    I_step(:, t) = I;

    % Update v
    v = v + 0.5 * (0.04 * v.^2 + 5 * v + 140 - u + I);
    v = v + 0.5 * (0.04 * v.^2 + 5 * v + 140 - u + I);

    % Update u
    u = u + a .* (b .* v - u);

    % Avoid nans
    v(isnan(v)) = c(isnan(v));
    
    v_step(:, t) = v;

end


%% Display
% show_frame.CData = spikes_step;
show_frame.CData = v_step;

