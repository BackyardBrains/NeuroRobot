
% close all
clear
clc

step_fig = 0;

%% Ontology
classifier_dir_name = '.\Data_1\Rec_2\';
labels = folders2labels(classifier_dir_name);
unique_states = unique(labels);
n_unique_states = length(unique_states);

%% Tuples
tuples_dir_name = 'C:\Users\Christopher Harris\Dropbox (CNE)\Operant\';
image_dir = dir(fullfile(tuples_dir_name, '**\*.png'));
torque_dir = dir(fullfile(tuples_dir_name, '**\*torques.mat'));
serial_dir = dir(fullfile(tuples_dir_name, '**\*serial_data.mat'));
ntuples = size(torque_dir, 1);

%% States
% load livingroom2_net
% get_states
load('states')
states = modefilt(states, [9 1]);

%% Torques
% get_torques
load('torque_data')

%% Distances
% get_dists
load('dists')

%% Actions
torque_vals = 2;
motor_combs = combinator(torque_vals, 2,'p','r') - ((0.5 * torque_vals) + 0.5);
motor_combs = motor_combs * 50;
motor_combs = [motor_combs(1:2,:); [0 0]; motor_combs(3:4,:)];
motor_combs = padarray(motor_combs, [0 1], rand * 0.00001, 'pre');
motor_combs = padarray(motor_combs, [0 1], rand * 0.00001, 'post');
n_unique_actions = size(motor_combs, 1);
% get_actions
load('actions')

%% Checksum
disp(horzcat('n unique states: ', num2str(n_unique_states)))
disp(horzcat('n uniqe actions: ', num2str(n_unique_actions)))
disp(horzcat('n tuples: ', num2str(ntuples)))

%% Prepare figure
if step_fig
    figure(1)
    clf
    subplot(1,2,1)
    left_eye = image(zeros(227, 227, 3));
    left_title = title('');
    subplot(1,2,2)
    right_eye = image(zeros(227, 227, 3));
    right_title = title('');
end

%% 
image_buffer = [];
state_buffer = [];
next_state_buffer = [];
torque_buffer = [];
action_buffer = [];
dist_buffer = [];
atuples = zeros(ntuples - 1, 3);
btuples = [];
btorques = [];
moving = 0;
moving_counter = [];
% xtuples = randsample(ntuples - 1, ntuples - 1);
% ytuples = randsample(ntuples - 1, ntuples - 1);
stepcount = 0;
for ntuple = 1:ntuples - 1

%     ntuple = xtuples(xtuple);
    if ~rem(ntuple, round((ntuples-1)/10))
        disp(num2str(ntuple/(ntuples-1)))
    end

    this_state = states(ntuple);
    this_action = actions(ntuple);
    these_torques = torque_data(ntuple, :);
    
%     this_next_state = states(ytuples(ntuple) + 1);
    this_next_state = states(ntuple + 1);
    this_dist = dists(ntuple);
    
    str1 = image_dir(ntuple*2-1).name;
    str1(end-15:end) = [];
    str2 = image_dir(ntuple*2).name;
    str2(end-16:end) = [];
    str3 = torque_dir(ntuple).name;
    str3(end-11:end) = [];

    if ~strcmp(str1, str2)
        disp(horzcat('str1: ', str1))
        disp(horzcat('str2: ', str2))
        error('image mismatch')
    end
    if ~strcmp(str1, str3)
        disp(horzcat('str1: ', str1))
        disp(horzcat('str3: ', str3))        
        error('image/torque mismatch')
    end

    if step_fig
        for ii = 1:2
            this_ind = ntuple*2-(ii-1);
            this_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
            if ii == 1
                left_eye_frame = this_im;
            elseif ii == 2
                right_eye_frame = this_im;
            end    
        end
%     image_buffer = [image_buffer; binocular];        
    end

    state_buffer = [state_buffer; this_state];
    next_state_buffer = [next_state_buffer; this_next_state];
    torque_buffer = [torque_buffer; these_torques];
    action_buffer = [action_buffer; this_action];
    dist_buffer = [dist_buffer; this_dist];

    
%     if sum(torques)
    if this_next_state ~= this_state
%     if stepcount < 10
%         stepcount = stepcount + 1;
        moving = moving + 1;
    elseif moving
%     elseif stepcount
        moving_counter = [moving_counter moving];
        moving = 0;
%         stepcount = 0;
        
        motor_vector = mean(torque_buffer(1:end-1, :), 1);
        motor_vector = padarray(motor_vector, [0 1], rand * 0.00001, 'pre');
        motor_vector = padarray(motor_vector, [0 1], rand * 0.00001, 'post');
        r = corr(motor_vector', motor_combs');  
        [~, this_action] = max(r);

        btuples = [btuples; state_buffer(1), next_state_buffer(end-1), this_action];
        btorques = [btorques; motor_vector];
        image_buffer = [];
        state_buffer = [];
        action_buffer = [];
        dist_buffer = [];
        torque_buffer = [];
        next_state_buffer = [];
    else
        image_buffer = [];
        state_buffer = [];
        action_buffer = [];
        torque_buffer = [];
        next_state_buffer = [];
        dist_buffer = [];
    end
    
    atuples(ntuple, 1) = this_state;
    atuples(ntuple, 2) = this_next_state;
    atuples(ntuple, 3) = this_action;

    if step_fig
        left_eye.CData = right_eye_frame;
        left_title.String = horzcat('S: ', char(unique_states(this_state)), ', A: ', num2str(this_action), ', Sx: ', char(unique_states(this_next_state)));
        right_eye.CData = left_eye_frame;
        right_title.String = horzcat('S: ', char(unique_states(this_state)), ', A: ', num2str(this_action), ', Sx: ', char(unique_states(this_next_state)));
        clc
        disp(horzcat('ntuple: ', num2str(ntuple), ' of ', num2str(ntuples)))
        disp(horzcat('S: ', char(unique_states(this_state)), ', A: ', num2str(this_action), ', Sx: ', char(unique_states(this_next_state))));
        disp(horzcat('S: ', num2str(this_state), ', A: ', num2str(this_action), ', Sx: ', num2str(this_next_state)))
        drawnow
        pause
    end
end


%% Get Markov Decision Process
% tuples = atuples;
tuples = btuples;
ntuples = size(tuples, 1);

mdp = createMDP(n_unique_states, n_unique_actions);
transition_counter = zeros(size(mdp.T));
for ntuple = 1:ntuples

    this_state = tuples(ntuple, 1);
    this_next_state = tuples(ntuple, 2);
    this_action = tuples(ntuple, 3);
    if this_state && this_next_state
        transition_counter(this_state, this_next_state, this_action) = transition_counter(this_state, this_next_state, this_action) + 1;
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
            while ~flag
                if sum(this_val) < 1
                    sum(this_val)
                    this_state = randsample(n_unique_states, 1);
                    this_val(this_state) = this_val(this_state) + 0.001;
                    disp('padded')
                else
                    flag = 1;
                end
            end
        end
        transition_counter(ii_state, :, naction) = this_val;
    end
end

mdp.T = transition_counter;

%% Plot mdp
figure(1)
clf
set(gcf, 'position', [100 50 1280 720], 'color', 'w')

subplot(2,2,1)
histogram(tuples(:,1), 'binwidth', 1)
title('States')
xlabel('State')
ylabel('States')

subplot(2,2,2)
histogram(tuples(:,3), 'binwidth', .25)
title('Actions')
xlabel('Action')
ylabel('Actions')

subplot(2,2,3)
imagesc(mean(transition_counter, 3), [0 0.5])
colorbar
title('Transitions')

subplot(2,2,4)
histogram(moving_counter)
set(gca, 'yscale', 'log')
title('Movements per sequence')
xlabel('Movements')
ylabel('Sequences')

export_fig(horzcat('mdp_', num2str(date)), '-r150', '-jpg', '-nocrop')

%% Get reward
reward_counter = zeros(size(mdp.R));
reward_counter = reward_counter - 1;
reward_counter(:,14,:) = 10;
mdp.R = reward_counter;
disp(horzcat('total reward: ', num2str(sum(reward_counter(:)))))
% mdp.TerminalStates = "s14";

%% Scramble 
save('mdp', 'mdp')
for nstate = 1:n_unique_states
    for naction = 1:n_unique_actions
        this_array = mdp.T(nstate, :, naction);
        mdp.T(nstate, :, naction) = this_array(randperm(length(this_array)));
    end
end
save('mdp_rand', 'mdp')

figure(1)
subplot(1,2,1)
load('mdp')
imagesc(mean(mdp.T, 3), [0 0.2])
title('MDP')
subplot(1,2,2)
load('mdp_rand')
imagesc(mean(mdp.T, 3), [0 0.2])
title('RMDP')

