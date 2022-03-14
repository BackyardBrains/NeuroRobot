

%% States
nsensors = 2;
nfeatures = 4;
state_combs = combinator(2, nsensors * nfeatures,'p','r') - 1;
state_combs = padarray(state_combs, [0 1], 0, 'pre');
state_combs = padarray(state_combs, [0 1], 1, 'post');
nstates = size(state_combs, 1);
disp(horzcat('nstates: ', num2str(nstates)))

%% Motors
nmotors = 2;
ntorques = 5; % Should be odd number
motor_combs = combinator(ntorques, nmotors,'p','r') - ((0.5 * ntorques) + 0.5);
motor_combs = padarray(motor_combs, [0 1], -floor(ntorques/2), 'pre');
motor_combs = padarray(motor_combs, [0 1], floor(ntorques/2), 'post');
nactions = size(motor_combs, 1);
disp(horzcat('nstates: ', num2str(nactions)))


%% Transitions
sum_transitions = sum(transition_counter(:));

%% Reward
sum_rewards = sum(reward_counter(:));
[max_reward_val, max_reward_ind] = max(reward_counter(:));


% Do a plot showing how rewarding certain states relative to how often they
% happened
% diff transition counter reward counter but normalized
reward_counter = reward_counter ./ transition_counter;
%%
for ii_state = 1:nstates
    for jj_state = 1:nstates
        for naction = 1:nactions
            transition_count = transition_counter(ii_state, jj_state, naction);
            reward_count = reward_counter(ii_state, jj_state, naction);
            if reward_count > 0.75
                clc
                disp(horzcat('state ii jj: ', num2str([ii_state jj_state])))
%                 disp(horzcat('action: ', num2str(naction)))
%                 disp(horzcat('reward: ', num2str(reward_count)))
%                 figure(10)
%                 clf
%                 subplot(2,1,1)
%                 imagesc(state_combs(ii_state,2:end-1) + state_combs(jj_state,2:end-1))
%                 title('Rewarded State')
%                 colorbar
%                 subplot(2,1,2)                
%                 imagesc(motor_combs(naction,2:end-1) + motor_combs(naction,2:end-1))         
%                 title('Rewarded Action')
%                 colorbar
%                 disp('')
            end
        end
    end
end
