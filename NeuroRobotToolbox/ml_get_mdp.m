%% Get Markov Decision Process

axes(ax8)
cla
tx8 = text(0.03, 0.5, horzcat('creating world model (MDP)...'));
drawnow

mdp = createMDP(n_unique_states, n_unique_actions);
transition_counter = zeros(size(mdp.T));
for ntuple = 1:ntuples

    this_state = tuples(ntuple, 1);
    this_next_state = tuples(ntuple, 2);
    this_action = tuples(ntuple, 3);
    if ~isnan(this_state) && ~isnan(this_next_state)
        if this_state && this_next_state
            transition_counter(this_state, this_next_state, this_action) = transition_counter(this_state, this_next_state, this_action) + 1;
        end
    end
end

disp(horzcat('n transitions: ', num2str(sum(transition_counter(:)))))
transition_counter_save = transition_counter;

for ii_state = 1:n_unique_states
    for naction = 1:n_unique_actions
        this_sum = sum(transition_counter(ii_state, :, naction));
        if this_sum
            this_val = transition_counter(ii_state, :, naction) / this_sum;
        else
            this_val = zeros(size(transition_counter(ii_state, :, naction)));
            flag = 0;
            disp('padding mdp')
            while ~flag
                if sum(this_val) < 1
                    this_state = randsample(n_unique_states, 1);
                    this_val(this_state) = this_val(this_state) + 0.001;
                else
                    flag = 1;
                end
            end
        end
%         if naction == mode(actions)
%             transition_counter(ii_state, :, naction) = 0;
%             transition_counter(ii_state, ii_state, naction) = 1;
%         else
%             transition_counter(ii_state, :, naction) = this_val;
%         end
        transition_counter(ii_state, :, naction) = this_val;
    end
end

mdp.T = transition_counter;
disp('Markov ready')


%% Output

tx8.String = 'Markov ready';
drawnow

axes(im_ax1)
cla
imagesc(mean(transition_counter, 3), [0 0.3])
colorbar('location', 'manual', 'position', im_ax1_colb_pos);
title('Transition probabilities (avg across actions)')
ylabel('State')
xlabel('Next State')

ml_visualize_mdp
