

state_net_name = ml_name1_edit.String;

if isempty(state_net_name)
    ml_name1_edit.BackgroundColor = [1 0.25 0.25];
    pause(0.75)
    ml_name1_edit.BackgroundColor = [0.94 0.94 0.94];
else    
    ml_get_data_stats
    ml_get_similarity
    ml_get_clusters
    ml_quality
    ml_finalize_training_data
    if redo_state_clustering % or (re)start from there
    end
    ml_get_state_net
    ml_get_tuples_part1
    ml_get_tuples_part2
    if redo_action_clustering % or (re)start from there
    end
    ml_get_mdp
end

