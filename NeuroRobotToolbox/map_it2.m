
load rl_data.mat

%%
figure(2)
clf
set(2, 'position', [300 100 600 600])
axis([0 6 0 4])
title('Transitions')
hold on

ntuples = size(filelist, 1) / 2;
for ntuple = 1:ntuples-2
    this_state = rl_data(ntuple, 5);
    this_next_state = rl_data(ntuple, 6);    
    if ~sum(isnan([this_state this_next_state])) && this_state && this_next_state
        this_hippo = xdata(this_state, :);
        this_next_hippo = xdata(this_next_state, :);
        plot([this_hippo(1) this_next_hippo(1)] + (0.05 * rand), [this_hippo(2) this_next_hippo(2)] + (0.05 * rand), 'linewidth', 1, 'color', 'k')
    end

%     if ~rem(ntuple, round(ntuples/10))
        drawnow
        pause(0.05)
        disp(num2str(ntuple))
%     end
end
