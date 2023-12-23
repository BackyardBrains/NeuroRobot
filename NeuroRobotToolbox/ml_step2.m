

agent_name = ml_name2_edit.String;
if isempty(agent_name)
    ml_name2_edit.BackgroundColor = [1 0 0];
    pause(0.5)
    ml_name2_edit.BackgroundColor = [0.94 0.94 0.94];
    error('Name your decision network')
end

ml_set_rewards
ml_get_action_net

