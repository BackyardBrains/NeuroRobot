

close all
clear
clc

working_dir = '.\Experiences\Recording_17\';

%% Images
ims = imageDatastore('.\Experiences\Recording_17\*.png');
n = length(ims.Files);
frames = readall(ims);
nframes = length(frames);

%% States
nsensors = 2;
nfeatures = 5;
statemax = 1; % vis_pref_vals = 50, bag = 1
state_combs = combinator(2, nsensors * nfeatures,'p','r') - 1;
disp(horzcat('ndimensions per state: ', num2str(size(state_combs, 2))))
state_combs = padarray(state_combs, [0 1], 0, 'pre');
state_combs = padarray(state_combs, [0 1], statemax, 'post');
nstates = size(state_combs, 1);
disp(horzcat('nstates: ', num2str(nstates)))

%% Motors
nmotors = 2;
ntorques = 5; % Should be odd number
motor_combs = combinator(ntorques, nmotors,'p','r') - ((0.5 * ntorques) + 0.5);
motor_combs = padarray(motor_combs, [0 1], -floor(ntorques/2), 'pre');
motor_combs = padarray(motor_combs, [0 1], floor(ntorques/2), 'post');
nactions = size(motor_combs, 1);
disp(horzcat('nactions: ', num2str(nactions)))

%% Custom rewards
serials = dir(strcat(working_dir, '*serial_data.mat'));

%% Markov
mdp = createMDP(nstates, nactions);
transition_counter = zeros(size(mdp.T));
reward_counter = zeros(size(mdp.R));

%% Get tuples
tuples = dir(strcat(working_dir, '*tuple.mat'));
ntuples = size(tuples, 1);
rl_data = zeros(ntuples, 4);
state_data = zeros(ntuples, nsensors * nfeatures);
motor_data = zeros(ntuples, 2);
counter = 0;
missed_tuples = 0;
rand_tuples = randsample(1:2:ntuples, round(ntuples/3));
% load working_rand_tuples_2.mat
% rand_tuples = randsample(ntuples, ntuples);
disp(horzcat('Processing ', num2str(length(rand_tuples)), ' tuples...'))
for ntuple = rand_tuples

    counter = counter + 1;

    if ~rem(counter, round(length(rand_tuples)/5))
        disp(num2str(counter/length(rand_tuples)))
    end

    % Load data
    load(horzcat(working_dir, tuples(ntuple).name))

    % Get state
    state_vector = rl_tuple{1};
    if length(state_vector) == 20 
        state_vector([6:10, 16:20]) = [];
    end

    if length(rl_tuple{1}) == 10 || length(rl_tuple{1}) == 20

        state_data(ntuple, :) = state_vector;
        state_vector = padarray(state_vector, [0 1], 0, 'pre');
        state_vector = padarray(state_vector, [0 1], statemax, 'post');  % Change lone 1 to 50 to do vis_pref_vals  
        r = corr(state_vector', state_combs');
        [~, ind] = max(r);
        rl_state = ind;
    
        % Get action    
        motor_vector = rl_tuple{2};
        motor_vector(motor_vector > 250) = 250;
        motor_vector(motor_vector < -250) = -250;
        motor_data(ntuple, :) = motor_vector;
    
        motor_vector = padarray(motor_vector, [0 1], -250, 'pre');
        motor_vector = padarray(motor_vector, [0 1], 250, 'post');
        r = corr(motor_vector', motor_combs');
        [~, ind] = max(r);
        rl_action = ind;
    
        % Get reward
        load(horzcat(working_dir, serials(ntuple).name))
        this_distance = str2double(serial_data{3});
        this_distance(this_distance >= 4000) = 0;        
        if this_distance
            rl_reward = 1/this_distance;
        else
            rl_reward = 0;
        end

        % Get state
        state_vector = rl_tuple{4};
        if length(state_vector) == 20   
            state_vector([6:10, 16:20]) = [];
        end     

        state_data(ntuple, :) = state_vector;
        state_vector = padarray(state_vector, [0 1], 0, 'pre');
        state_vector = padarray(state_vector, [0 1], statemax, 'post');  % Change lone 1 to 50 to do vis_pref_vals
        r = corr(state_vector', state_combs');
        [~, ind] = max(r);
        rl_next_state = ind;
    
        % Update MDP
        transition_counter(rl_state, rl_next_state, rl_action) = transition_counter(rl_state, rl_next_state, rl_action) + 1;
        reward_counter(rl_state, rl_next_state, rl_action) = reward_counter(rl_state, rl_next_state, rl_action) + rl_reward;
    
        % Store data
        rl_data(ntuple, 1) = rl_state;
        rl_data(ntuple, 2) = rl_action;
        rl_data(ntuple, 3) = rl_reward;
        rl_data(ntuple, 4) = rl_next_state;

    else
        missed_tuples = missed_tuples + 1;
    end
end

disp(horzcat('n_missed_tuples: ', num2str(missed_tuples)))
disp(horzcat('n_unique_states: ', num2str(length(unique(rl_data(:,1))))))
disp(horzcat('%: ', num2str(100*(length(unique(rl_data(:,1)))/nstates))))
disp(horzcat('total reward: ', num2str(sum(rl_data(:,3)))))


%%
rl_data(rl_data(:,1) == 0, :) = [];

%%
figure(1)
clf
histogram(rl_data(:,1), 'binwidth', 1)
set(gca, 'yscale', 'log')

%%
unique_states = unique(rl_data(:,1));
for ii = unique_states'
    these_frames = rl_data(:,1) == ii;
    if sum(these_frames) > 50
        figure(ii)
        montage({frames{these_frames}})
        title(horzcat('State: ', num2str(ii)))
        pause
    end
end
