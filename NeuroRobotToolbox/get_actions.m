
actions = zeros(ntuples, 1);
disp('getting actions')

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/20))
        disp(num2str(ntuple/ntuples))
    end

    torques = torque_data(ntuple, :);
    torques(torques > 250) = 250;
    torques(torques < -250) = -250;

    motor_vector = torques;
    motor_vector = padarray(motor_vector, [0 1], rand * 0.00001, 'pre');
    motor_vector = padarray(motor_vector, [0 1], rand * 0.00001, 'post');
    r = corr(motor_vector', motor_combs');    
    [~, ind] = max(r);
    actions(ntuple) = ind;

end

save('actions', 'actions')
