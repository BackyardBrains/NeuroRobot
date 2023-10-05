

%% Get speed
if ml_speed_select.Value == 1 % Slow
    learn_speed = 1;
elseif ml_speed_select.Value == 2 % Medium
    learn_speed = 0.5;
elseif ml_speed_select.Value == 3 % Fast
    learn_speed = 0.1;    
end


%% Cluster data, train convnet and get MDP
ml_get_data_stats
ml_get_similarity
ml_get_clusters
ml_quality
ml_finalize_training_data
ml_get_state_net
ml_get_tuples
ml_get_mdp