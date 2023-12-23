
disp('Getting rewards...')
if get_rewards
    gnet = googlenet;
    rewards = zeros(ntuples, 1);
    for ntuple = 1:ntuples
        next_im = imread(strcat(image_dir(ntuple).folder, '\',  image_dir(ntuple).name));    
        % cup_score = sum(next_im(:));
        % cup_score = (sum(next_im(:))/(10^7)) - sum(abs(torque_data(ntuple, :)));  
        
        [~, scores] = classify(gnet, next_im(1:224,1:224,:));
        cup_score_left = max(scores([505 739 969]));
        [~, scores] = classify(gnet, next_im(1:224,79:302,:));    
        cup_score_right = max(scores([505 739 969]));
        cup_score = max([cup_score_left cup_score_right]) * 10;
        rewards(ntuple) = cup_score;
        disp(horzcat('ntuple = ', num2str(ntuple), ', done = ', num2str(100*(ntuple/ntuples)), '%, reward = ', num2str(cup_score)))
    end
    save(strcat(nets_dir_name, agent_name, '-rewards'), 'rewards')
else
    load(strcat(nets_dir_name, agent_name, '-rewards'))
end
