


fig2 = figure(2);
clf
set(fig2, 'color', 'w', 'position', [1 41 1536 749])

this_min = data(:,:,1);
this_min = min(this_min(:));
this_max = data(:,:,1);
this_max = max(this_max(:)); 

this_min2 = data(:,:,2);
this_min2 = min(this_min2(:));
this_max2 = data(:,:,2);
this_max2 = max(this_max2(:)); 


for nstate = 1:nstates
    if nstate == 1
        state_name = 'Baseline';
        drive_delta = 0;
        cue_delta = 0;
        dopamine_delta = 0;
        
    elseif nstate == 2
        state_name = 'Baseline + Weak cue';
        drive_delta = 0;
        cue_delta = weak_cue;
        dopamine_delta = 0;
        
    elseif nstate == 3
        state_name = 'Baseline + Strong cue';
        drive_delta = 0;
        cue_delta = strong_cue;
        dopamine_delta = 0;
        
    elseif nstate == 4
        state_name = 'Baseline + Reward';
        drive_delta = 0;
        cue_delta = 0;
        dopamine_delta = reward;
        
    elseif nstate == 5
        state_name = 'Baseline + Weak cue + Reward';
        drive_delta = 0;
        cue_delta = weak_cue;
        dopamine_delta = reward;
        
    elseif nstate == 6
        state_name = 'Baseline + Strong cue + Reward';
        drive_delta = 0;
        cue_delta = strong_cue;
        dopamine_delta = reward;
        
    elseif nstate == 7
        state_name = 'Low dopamine';
        drive_delta = low_d2;
        cue_delta = 0;
        dopamine_delta = 0;

    elseif nstate == 8
        state_name = 'Low dopamine + Weak cue';
        drive_delta = low_d2;
        cue_delta = weak_cue;
        dopamine_delta = 0;
        
    elseif nstate == 9
        state_name = 'Low dopamine + Strong cue';
        drive_delta = low_d2;
        cue_delta = strong_cue;        
        dopamine_delta = 0; 
        
    elseif nstate == 10
        state_name = 'Low dopamine + Reward';
        drive_delta = low_d2;
        cue_delta = 0;
        dopamine_delta = reward;
        
    elseif nstate == 11
        state_name = 'Low dopamine + Weak cue + Reward';
        drive_delta = low_d2;
        cue_delta = weak_cue;        
        dopamine_delta = reward;
        
    elseif nstate == 12
        state_name = 'Low dopamine + Strong cue + Reward';
        drive_delta = low_d2;
        cue_delta = strong_cue;        
        dopamine_delta = reward;
        
    end
      
    
    hAxes(nstate) = subplot(4,3,nstate);
    hold on
    for nnetwork = 1:nnetworks
        if nnetwork == 1
            col = 'b';
        elseif nnetwork == 2
            col = [0 0.7 0];
        elseif nnetwork == 3
            col = 'r';
        end
        
        yyaxis left    
        plot(nnetwork, data(nstate, nnetwork, 1), 'marker', '.', 'markersize', 20, 'linestyle', 'none', 'color', col)
        hAxes(nstate).YAxis(1).Limits = [0 this_max * 1.1];
        ylabel('# of selections')
        box on
        
        yyaxis right    
        plot(nnetwork, data(nstate, nnetwork, 2), 'marker', 'v', 'markersize', 10, 'linestyle', 'none', 'color', col)
        hAxes(nstate).YAxis(2).Limits = [0 this_max2 * 1.1];
        ylabel('% of total time')
        box on
        
    end

    xlim([0.2 nnetworks + 0.8])
    set(gca, 'xtick', 1:nnetworks')
%     xlabel('BG net')
%     axis tight
    title(state_name)

end    