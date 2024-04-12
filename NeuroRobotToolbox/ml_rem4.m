
r = [5 8];
l = [3 7];

% Facing the door, turning left
this_array = mdp.T([9 11 13],:,l);
this_array = mean(this_array, [1 3]);

figure(4)
clf
bar(this_array)
xlabel('State')
ylabel('Transition probability')
title('Sanity check')
