

state_net_name = ml_name1_edit.String;

if isempty(state_net_name)
    ml_name1_edit.BackgroundColor = [1 0.25 0.25];
    pause(0.75)
    ml_name1_edit.BackgroundColor = [0.94 0.94 0.94];
else
    if ml_flag == 1
        ml_get_data_stats
        ml_get_similarity
        ml_get_clusters
        ml_quality
        ml_finalize_training_data
    end

    if sum(ml_flag == [1 2])
        ml_get_state_net
    end

    if sum(ml_flag == [1 2 3])
        ml_get_tuples_part1
    end

    if sum(ml_flag == [1 2 3 4])
        ml_get_tuples_part2
        ml_get_mdp
    end
end

