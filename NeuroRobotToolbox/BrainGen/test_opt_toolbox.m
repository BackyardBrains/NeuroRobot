
close all
clear

nneurons = 100;
nsteps = 3000;

start_brain = zeros(nneurons + 4, nneurons);
start_brain(1,:) = repmat(0.02, [nneurons, 1]);
start_brain(2,:) = repmat(0.2, [nneurons, 1]);
start_brain(3,:) = repmat(-65, [nneurons, 1]);
start_brain(4,:) = repmat(2, [nneurons, 1]);
v1 = reshape(start_brain, [(nneurons + 4) * nneurons, 1]);
x = reshape(v1, [nneurons + 4, nneurons]);

% Lower bounds
lb = zeros(size(start_brain));
lb(1,:) = 0;
lb(2,:) = 0;
lb(3,:) = -90;
lb(4,:) = 0;
lb(4:nneurons+4,:) = -30;
v2 = reshape(lb, [(nneurons + 4) * nneurons, 1]);

% Upper bounds
ub = zeros(size(start_brain));
ub(1,:) = 0.15;
ub(2,:) = 0.4;
ub(3,:) = -30;
ub(4,:) = 10;
ub(4:nneurons+4,:) = 30;
v3 = reshape(ub, [(nneurons + 4) * nneurons, 1]);

% Placeholder optimizer expects
A = [];
b = [];
Aeq = [];
beq = [];

% fmincon
% options = optimoptions('fmincon','Display','iter');
% [x, fval] = fmincon(@brainSim2, start_brain, A, b, Aeq, beq, lb, ub, [], options)

% % patternsearch
% options = optimoptions('patternsearch','Display','iter', 'PlotFcn',{@psplotbestf,@psplotfuncount});
% x = patternsearch(@brainSim2, start_brain, A, b, Aeq, beq, lb, ub, [], options);

% particleswarm
options = optimoptions('particleswarm', 'Display', 'iter', ...
    'PlotFcn',{@psplotbestf,@psplotfuncount},'SwarmSize',100,'HybridFcn',@fmincon);
options.InitialSwarmMatrix = v1;
nvars = length(v1);
[x,fval,exitflag,output] = particleswarm(@brainSim2,nvars,v2,v3);

formatstring = 'particleswarm reached the value %f using %d function evaluations.\n';
fprintf(formatstring,fval,output.funccount)

x = reshape(x, [nneurons + 4, nneurons]);

% genetic algorithm
% options = optimoptions('ga','Display','iter', 'PlotFcn',{@psplotbestf,@psplotfuncount});
% nvars = length(start_brain(:));
% x = ga(@brainSim2, nvars, start_brain, A, b, Aeq, beq, lb, ub, [], options);


% Reshape to brain
a = x(1,:)';
b = x(2,:)';
c = x(3,:)';
d = x(4,:)';
for nneuron = 1:nneurons
    connectome(nneuron,:) = x(4+nneuron,:);
end

% Run brain
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

% Get intended activity
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

% Plot intended and actual activity
this_diff = sum(abs(mean_activity' - intended_activity));
figure(1)
clf
set(gcf, 'position', [200 400 855 277], 'color', 'w')
plot(mean_activity, 'color', [0.2 0.4 0.8])
hold on
plot(intended_activity, 'color', [0.8 0.4 0.2])
ylim([0 1.3])
legend('Actual network activity', 'Intended network activity')
title(horzcat('Actual vs intended network activity, diff score = ', num2str(this_diff)))
xlabel('Time')

% saved_brain_1 = x;
% save('saved_brain_1','saved_brain_1')