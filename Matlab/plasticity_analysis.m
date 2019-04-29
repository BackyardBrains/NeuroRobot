
nsteps = 1000;
data = zeros(nsteps, 1);
d3 = 0;
for nstep = 1:nsteps
    
    if nstep < 300
        d3 = d3 + 0.5;
    end
    data(nstep) = sigmoid(d3, 80, 0.06);  
end

figure(1)
clf
set(gcf, 'color', 'w', 'position', [340 240 1060 600])
plot(0.1:0.1:nsteps/10, data, 'linestyle', '-.', 'marker', '.', 'markersize', 20, 'color', 'k')
xlabel('Time (s)')
ylabel('Synaptic strength (w)')
% export_fig('plasticity', '-r150', '-jpg', '-nocrop')

% bdata(:,1) = adata;

%%
figure(11)
clf
set(11, 'color', 'w', 'position', [560 260 600/3 640/3])
plot(0.1:0.1:120, bdata(:,2:4), 'linestyle', '-.', 'marker', '.', 'markersize', 5, 'color', 'k')
axis([0 120 0 35])
xlabel('Time (s)')
ylabel('Synaptic strength')
title('Learning and forgetting')
export_fig('plasticity_exponential', '-r300', '-jpg', '-nocrop')
