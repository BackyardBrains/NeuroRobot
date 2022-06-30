


%%
figure(2)
clf
set(2, 'position', [300 100 600 600])
axis([0 6 0 4])
title('Transitions')
hold on
for ntuple = 1:nserials-2
    this_state = rl_data(ntuple, 1);
    this_next_state = rl_data(ntuple + 1, 4);    
    if ~sum(isnan([this_state this_next_state])) && this_state && this_next_state
        this_hippo = xdata(this_state, :);
        this_next_hippo = xdata(this_next_state, :);
        plot([this_hippo(1) this_next_hippo(1)] + (0.05 * rand), [this_hippo(2) this_next_hippo(2)] + (0.05 * rand), 'linewidth', 1, 'color', 'k')
    end
    if ~rem(ntuple, round(nserials/10))
        drawnow
        disp(num2str(ntuple))
    end
end
