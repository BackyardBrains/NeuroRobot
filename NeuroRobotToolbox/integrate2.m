

%%
load('states_rand')
load('torque_data_rand')
load('actions_rand')
load('mdp_rand')
load('transition_counter_save_rand')

rstates = states;
rtorque_data = torque_data;
ractions = actions;
rmdp = mdp;
rtransition_counter_save = transition_counter_save;

%%
load('states')
load('torque_data')
load('actions')
load('mdp')
load('transition_counter_save')

%%
figure(1)
clf
subplot(1,2,1)
histogram(rstates, 'facecolor', [0.2 0.4 0.8])
hold on
histogram(states, 'facecolor', [0.2 0.8 0.2])
title('States')
subplot(1,2,2)
histogram(ractions, 'facecolor', [0.2 0.4 0.8])
hold on
histogram(actions, 'facecolor', [0.2 0.8 0.2])
title('Actions')

%%
figure(2)
clf
subplot(1,2,1)
imagesc(mean(rmdp.T, 3), [0 0.5])
title('Transitions (rand)')
subplot(1,2,2)
imagesc(mean(mdp.T, 3), [0 0.5])
title('Transitionss')

