
torque_data = zeros(ntuples, 2);
for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end

    torque_fname = horzcat(torque_dir(ntuple).folder, '\', torque_dir(ntuple).name);
    load(torque_fname)
    torques(torques > 250) = 250;
    torques(torques < -250) = -250;
    torque_data(ntuple, :) = torques;

end

save('torque_data', 'torque_data')

