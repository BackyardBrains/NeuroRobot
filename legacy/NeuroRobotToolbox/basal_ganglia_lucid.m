
%% Lucid dream
% Demo Sleep:Basal Ganglia


%% Prepare
figure(9)
clf
set(gcf, 'position', [80 80 1320 600], 'color', 'w')
ax1 = axes('position', [0.05 0.2 0.4 0.65]);
im1 = image(zeros(227, 227, 3, 'uint8'));
set(gca, 'xtick', [], 'ytick', [])
tx1 = title('');
ax2 = axes('position', [0.55 0.2 0.4 0.65]);
im2 = image(zeros(227, 227, 3, 'uint8'));
set(gca, 'xtick', [], 'ytick', [])
tx2 = title('');
ax3 = axes('position', [0.3 0.025 0.4 0.05], 'xcolor', 'w', 'ycolor', 'w');
plot([0 10], [0 10], 'color', 'w')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
tx3 = text(5, 5, '', 'HorizontalAlignment','center', 'VerticalAlignment', 'middle');


%%
imdim = 227;
rinds = randsample(ntuples-5, 100, 0);
for start_tuple = rinds'

%     ntuple = start at random ind and proceed sequentially, hopefully
%     showing how action and states are entangled

    for ntuple = start_tuple:start_tuple + 50
        this_ind = ntuple*2-1;    
        now_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
        now_im = imresize(now_im, [imdim imdim]);        
        im1.CData = now_im;
        this_state = char(labels(states(ntuple)));
        this_state(this_state=='_') = [];
        tx1.String = horzcat('Tuple: ', num2str(ntuple), ', state: ', num2str(states(ntuple)), ' (', this_state, ')');
        
        this_ind = (ntuple + 5)*2-1;
        next_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
        next_im = imresize(next_im, [imdim imdim]);
        im2.CData = next_im;
        this_state = char(labels(states(ntuple + 5)));
        this_state(this_state=='_') = [];        
        tx2.String = horzcat('Prime tuple: ', num2str(ntuple + 5), ' , state: ', num2str(states(ntuple + 5)), ' (', this_state, ')');
    
        this_motor_vector = torque_data(ntuple, :);
        this_action = actions(ntuple);
        tx3.String = horzcat('Action: ', num2str(this_action), ', left: ', num2str(this_motor_vector(1)), ', right: ', num2str(this_motor_vector(2)));
           
        drawnow
        pause
    end

end

