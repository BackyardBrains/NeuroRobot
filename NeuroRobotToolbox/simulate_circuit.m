
% This script allows you to quickly get the spiking statistics of different
% circuits

% close all
clear

% Circuit settings
nneurons = 1;
nsteps = 10000;
b_range = 0.1:0.01:0.2;
results = zeros(length(b_range), 3);

% Preconfigure
a = zeros(nneurons, 1);
b = zeros(nneurons, 1);
c = zeros(nneurons, 1);
d = zeros(nneurons, 1);
connectome = zeros(nneurons, nneurons);
spike_log = zeros(nneurons, nsteps);
v(:, 1) = -65 + 5 * randn(nneurons,1);
u = b .* v;

% Build brain
counter = 0;
for bx = b_range
    counter = counter + 1
    
    for nneuron = 1:nneurons
        a(nneuron, 1) = 0.02;
        b(nneuron, 1) = bx;
        c(nneuron, 1) = -65;
        d(nneuron, 1) = 2;
%         if rand < 0.5
%             for nneuron2 = 1:nneurons
%                 connectome(nneuron, nneuron2) = 1;
%             end
%         end    
    end

    % Run brain
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

    % Get data
    nspikes = sum(spike_log);
%     disp(horzcat('nspikes = ', num2str(nspikes)))

    isis = diff(find(spike_log));
%     disp(horzcat('mean isi = ', num2str(mean(isis))))
%     disp(horzcat('sd isi = ', num2str(std(isis))))

    results(counter, 1) = nspikes;
    results(counter, 2) = mean(isis);
    results(counter, 3) = std(isis);

end

figure(1)
clf
subplot(1,3,1)
plot(b_range, results(:,1))
title('Spikes per 10 s')
subplot(1,3,2)
plot(b_range, results(:,2))
subplot(1,3,3)
plot(b_range, results(:,3))


