

%% Get Markov Decision Process
try
axes(ml_train4_status)
cla
tx8 = text(0.03, 0.5, horzcat('Creating transition matrix...'), 'FontSize', bfsize + 4);
drawnow
catch
end

mdp = createMDP(n_unique_states, n_unique_actions);
transition_counter = zeros(size(mdp.T));
for ntuple = 1:ntuples

    this_state = tuples(ntuple, 1);
    this_next_state = tuples(ntuple, 2);
    this_action = tuples(ntuple, 3);
    if ~isnan(this_state) && ~isnan(this_next_state) && sum(this_action == main_actions)
        if this_state && this_next_state
            transition_counter(this_state, this_next_state, this_action) = transition_counter(this_state, this_next_state, this_action) + 1;
        end
    end
end

disp(horzcat('n transitions: ', num2str(sum(transition_counter(:)))))
transition_counter_save = transition_counter;


%% Normalize mdp
for ii_state = 1:n_unique_states
    for naction = 1:n_unique_actions
        this_sum = sum(transition_counter(ii_state, :, naction));
        if this_sum
            this_val = transition_counter(ii_state, :, naction) / this_sum;
        else
            % transition_counter(ii_state, :, naction) = 0;
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
        transition_counter(ii_state, :, naction) = this_val;
    end
end

mdp.T = transition_counter;
save(strcat(nets_dir_name, state_net_name, '-mdp'), 'mdp')
disp('Ready to train decision network')


%% Output
try
tx8.String = 'Ready to train decision network';
drawnow
catch
end

ml_visualize_mdp

