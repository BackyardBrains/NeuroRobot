
clear
clc


%% Ontology
classifier_dir_name = '.\Data_1\Rec_2\';
labels = folders2labels(classifier_dir_name);
unique_states = unique(labels);
n_unique_states = length(unique_states);

%% Tuples
tuples_dir_name = '.\Data_3\';
image_dir = dir(fullfile(tuples_dir_name, '**\*.png'));
ntuples = size(image_dir, 1)/2;

%% States
% load livingroom2_net
% get_states
load('states.mat')
mode_states = modefilt(states, [9 1]);

%% Torques
torque_dir = dir(fullfile(tuples_dir_name, '**\*torques.mat'));
% get_torques
load('torque_data')

%% Actions
torque_vals = 2;
motor_combs = combinator(torque_vals, 2,'p','r') - ((0.5 * torque_vals) + 0.5);
motor_combs = motor_combs * 500;
motor_combs = [motor_combs(1:2,:); [0 0]; motor_combs(3:4,:)];
motor_combs = padarray(motor_combs, [0 1], rand * 0.001, 'pre');
motor_combs = padarray(motor_combs, [0 1], rand * 0.001, 'post');
n_unique_actions = size(motor_combs, 1);
% get_actions
load('actions')

%% Checksum
if ntuples ~= length(torque_data)
    disp('unequeal number of states and torques!!!')
end

disp(horzcat('n unique states: ', num2str(n_unique_states)))
disp(horzcat('n uniqe actions: ', num2str(n_unique_actions)))
disp(horzcat('n tuples: ', num2str(ntuples)))

% %% Prepare figure
% figure(1)
% clf
% subplot(1,2,1)
% left_eye = image(zeros(227, 227, 3));
% left_title = title('');
% subplot(1,2,2)
% right_eye = image(zeros(227, 227, 3));
% right_title = title('');

%% 
image_buffer = [];
state_buffer = [];
next_state_buffer = [];
torque_buffer = [];
action_buffer = [];
atuples = zeros(ntuples - 1, 3);
btuples = [];
moving = 0;
moving_counter = [];
for ntuple = 1:ntuples - 1

    if ~rem(ntuple, round((ntuples-1)/10))
        disp(num2str(ntuple/(ntuples-1)))
    end

    this_state = states(ntuple);
    this_action = actions(ntuple);
    these_torques = torque_data(ntuple, :);
    this_next_state = states(ntuple + 1);
    
    for ii = 1:2
        this_ind = ntuple*2-(ii-1);
        this_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
        if ii == 1
            left_eye_frame = this_im;
        elseif ii == 2
            right_eye_frame = this_im;
        end    
    end

    image_buffer = [image_buffer; left_eye_frame right_eye_frame];
    state_buffer = [state_buffer; this_state];
    next_state_buffer = [next_state_buffer; this_next_state];
    torque_buffer = [torque_buffer; these_torques];
    action_buffer = [action_buffer; this_action];

%     if sum(torques)
    if this_next_state ~= this_state
        moving = moving + 1;
    elseif moving
        moving_counter = [moving_counter moving];
        disp(horzcat('processing sequence of ', num2str(moving), ' actions'))
        moving = 0;
%         btuples = [btuples; state_buffer(1), next_state_buffer(end), this_action];
%         disp(num2str(btuples))

        image_buffer = [];
        state_buffer = [];
        action_buffer = [];
        torque_buffer = [];
        next_state_buffer = [];
    else
        disp('waiting for movement')
    end
    
    atuples(ntuple, 1) = this_state;
    atuples(ntuple, 2) = this_next_state;
    atuples(ntuple, 3) = this_action;

%     left_eye.CData = right_eye_frame;
%     left_title.String = horzcat('S: ', char(unique_states(this_state)), ', A: ', num2str(this_action), ', Sx: ', char(unique_states(this_next_state)));
%     right_eye.CData = left_eye_frame;
%     right_title.String = horzcat('S: ', char(unique_states(this_state)), ', A: ', num2str(this_action), ', Sx: ', char(unique_states(this_next_state)));
%     clc
%     disp(horzcat('ntuple: ', num2str(ntuple), ' of ', num2str(ntuples)))
%     disp(horzcat('S: ', char(unique_states(this_state)), ', A: ', num2str(this_action), ', Sx: ', char(unique_states(this_next_state))));
%     disp(horzcat('S: ', num2str(this_state), ', A: ', num2str(this_action), ', Sx: ', num2str(this_next_state)))
%     drawnow
%     pause

end


%% Get Markov Decision Process
tuples = atuples;
% tuples = btuples; % adjust montage


mdp = createMDP(nstates, nactions);
transition_counter = zeros(size(mdp.T));
for ntuple = 1:nimages

    this_state = tuples(ntuple, 1);
    this_next_state = tuples(ntuple, 2);
    this_action = tuples(ntuple, 3);
    if this_state && this_next_state
        transition_counter(this_state, this_next_state, this_action) = transition_counter(this_state, this_next_state, this_action) + 1;
    end
end

transition_counter_save = transition_counter;

%%
transition_counter = transition_counter_save;

for ii_state = 1:nstates
    for naction = 1:nactions
        this_sum = sum(transition_counter(ii_state, :, naction));
        if this_sum
            this_val = transition_counter(ii_state, :, naction) / this_sum;
        else
            this_val = zeros(size(transition_counter(ii_state, :, naction)));
            this_val(ii_state) = 0.5;
            flag = 0;
            while ~flag
                if sum(this_val) < 1
                    this_state = randsample(1:nstates, 1);
                    if this_state ~= ii_state
                        this_val(this_state) = 0.05;
                        disp('padded')
                    end
                else
                    flag = 1;
                end
            end
        end
        transition_counter(ii_state, :, naction) = this_val;
    end
end

mdp.T = transition_counter;
save('transition_counter', 'transition_counter')

%% Plot mdp
figure(1)
clf
set(gcf, 'position', [100 50 1280 720], 'color', 'w')

subplot(2,2,1)
histogram(tuples(:,1), 'binwidth', 1)
title('States (location and heading)')
xlabel('State')
ylabel('Count')

subplot(2,2,2)
histogram(tuples(:,2), 'binwidth', 0.2)
set(gca, 'xtick',0:1:nactions+1, 'xticklabel', 0:nactions+1)
title('Actions (torque combinations)')
xlabel('Action')
ylabel('#')

subplot(2,2,3)
imagesc(mean(transition_counter, 3))
title('Transitions')

% subplot(2,2,4)
% histogram(bufl)
% title('Movements per transition')

export_fig(horzcat('agent_5_', num2str(date), '_mdp'), '-r150', '-jpg', '-nocrop')

