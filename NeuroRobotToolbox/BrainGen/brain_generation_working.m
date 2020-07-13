

% BrainGen
% Backyard Brains
%
% This code generates a brain at a random point in the space of all possible brains.
% Aim: Apply Matlab ML and generative ANNs to existing brains and new brains that receive significant reward from users
% See brain_generation_full for extended parameter search


close all
clear


%% Brain parameters
nneurons = 200;


%% Settings
ms_per_step = 3000;


%% Desired network activity
this_act = zeros(ms_per_step, 1);
x = exp(0.02:0.02:10);
for ii = 1:ms_per_step
    if ii <= 500
        this_act(ii) = x(ii);
    elseif ii <= 1000
        this_act(ii) = x(ii-500);
    elseif ii <= 1500
        this_act(ii) = x(ii-1000);
    elseif ii <= 2000
        this_act(ii) = x(ii-1500);
    elseif ii <= 2500
        this_act(ii) = x(ii-2000);
    elseif ii <= 3000
        this_act(ii) = x(ii-2500);
%     elseif ii <= 3500
%         this_act(ii) = x(ii-3000);  
%     elseif ii <= 4000
%         this_act(ii) = x(ii-3500);
%     elseif ii <= 4500
%         this_act(ii) = x(ii-4000);
%     elseif ii <= 5000
%         this_act(ii) = x(ii-4500);
%     elseif ii <= 5500
%         this_act(ii) = x(ii-5000);
%     elseif ii <= 6000
%         this_act(ii) = x(ii-5500);   
%     elseif ii <= 6500
%         this_act(ii) = x(ii-6000);
%     elseif ii <= 7000
%         this_act(ii) = x(ii-6500);
%     elseif ii <= 7500
%         this_act(ii) = x(ii-7000);
%     elseif ii <= 8000
%         this_act(ii) = x(ii-7500);
%     elseif ii <= 8500
%         this_act(ii) = x(ii-8000); 
%     elseif ii <= 9000
%         this_act(ii) = x(ii-8500);
%     elseif ii <= 9500
%         this_act(ii) = x(ii-9000);  
    else
        this_act(ii) = x(ii-9500);
    end
end
this_act = this_act - min(this_act);
this_act = this_act / max(this_act);


%% Search parameter space
bs = 0.1 : 0.02 : 0.25;
ws = 0 : 1 : 20;
ps = 0.1 : 0.1 : 1;
ps2 = 0.1 : 0.1 : 1;
nsearches = length(bs) * length(ws) * length(ps) * length(ps2);
nsearch = 0;
max_r = 0;
for iib = bs
    for iiw = ws
        for iip = ps
            for iip2 = ps2
        
                tic
                nsearch = nsearch + 1;

                %% Set parameters
                a = zeros(nneurons, 1);
                b = zeros(nneurons, 1);
                c = zeros(nneurons, 1);
                d = zeros(nneurons, 1);
                connectome = zeros(nneurons, nneurons);

                for nneuron = 1:nneurons
                    a(nneuron, 1) = 0.02;
                    b(nneuron, 1) = iib;
                    c(nneuron, 1) = -65;
                    d(nneuron, 1) = 2;
                    if rand < iip
                        for nneuron2 = 1:nneurons
                            if rand < iip
                                connectome(nneuron, nneuron2) = iiw;
                            end
                        end
                    end
                    if rand < iip2
                        for nneuron2 = 1:nneurons
                            if rand < iip2
                                connectome(nneuron, nneuron2) = -iiw;
                            end
                        end
                    end                
                end


                %% Simulate
                spikes_step = zeros(nneurons, ms_per_step);

                clear v
                v(:, 1) = -65 + 5 * randn(nneurons,1);
                u = b .* v;

                for t = 1:ms_per_step

                    % Add noise
                    I = 5 * randn(nneurons, 1);       

                     % Find spiking neurons
                    fired_now = v >= 30;
                    spikes_step(fired_now, t) = 1;

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


                %% Correlate with intended network activity
                net_act = mean(spikes_step);
                net_act = net_act - min(net_act);
                net_act = net_act / max(net_act);
                [r, p] = corr(net_act', this_act);


                %% If correlation is highest ever, plot activity and save parameters
                if r > max_r
                    max_r = r;

                    % Plot activity
                    figure(1)
                    clf
                    set(gcf, 'position', [1921 1 1920 1003], 'color', 'w')

                    subplot(2,1,1)
                    plot(net_act, 'color', [0.2 0.4 0.8])
                    hold on
                    plot(this_act, 'color', [0.8 0.4 0.2])
                    title(horzcat('Intended (blue) vs actual (orange) network activity, corr = ', num2str(r)))
                    xlabel('Time')

                    % Save parameters
                    saved_a = a;
                    saved_b = b;
                    saved_c = c;
                    saved_d = d;
                    saved_w = iiw;
                    saved_connectome = connectome;
                    saved_p = iip;
                    saved_p2 = iip2;
                end
                disp(horzcat('nsearch = ', num2str(nsearch), ' of ', num2str(nsearches), ', search time = ', num2str(toc)))
            end
        end
    end
end

disp(horzcat('saved b = ', num2str(mode(saved_b))))
disp(horzcat('saved w = ', num2str(mode(saved_w))))
disp(horzcat('saved p = ', num2str(mode(saved_p))))
disp(horzcat('saved p2 = ', num2str(mode(saved_p2))))


%% Load previous
load store2
saved_a = store.saved_a;
saved_b = store.saved_b;
saved_c = store.saved_c;
saved_d = store.saved_d;
saved_connectome = store.connectome;
nneurons = store.nneurons;
ms_per_step = 3000;


%% Simulate
clear v
v(:, 1) = -65 + 5 * randn(nneurons,1);
u = saved_b .* v;
spikes_step = zeros(nneurons, ms_per_step);
for t = 1:ms_per_step

    % Add noise
    I = 5 * randn(nneurons, 1);       

     % Find spiking neurons
    fired_now = v >= 30;
    spikes_step(fired_now, t) = 1;

    % Reset spiking v to c
    v(fired_now) = saved_c(fired_now);

    % Adjust spiking u to d
    u(fired_now) = u(fired_now) + saved_d(fired_now);

    % Add spiking synaptic weights to neuronal inputs
    I = I + sum(saved_connectome(fired_now,:), 1)';

    % Update v
    v = v + 0.5 * (0.04 * v.^2 + 5 * v + 140 - u + I);
    v = v + 0.5 * (0.04 * v.^2 + 5 * v + 140 - u + I);

    % Update u
    u = u + saved_a .* (saved_b .* v - u);

    % Avoid nans
    v(isnan(v)) = saved_c(isnan(v));

end

net_act = mean(spikes_step);

subplot(2,1,2)
plot(net_act, 'color', [0.2 0.4 0.8])
title('Second run')
xlabel('Time')
