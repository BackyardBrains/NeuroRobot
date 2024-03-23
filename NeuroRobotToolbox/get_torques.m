
torque_data = zeros(ntuples, 2);
disp(horzcat('Getting ', num2str(ntuples), ' torques'))

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(horzcat('done = ', num2str(round((100 * (ntuple/ntuples)))), '%'))
    end

    torque_fname = horzcat(torque_dir(ntuple).folder, '\', torque_dir(ntuple).name);
    raw_torques = readtable(torque_fname);

    if ~isempty(raw_torques)
        torque_str = char(raw_torques.Var1);
        semis = strfind(torque_str, ';');
        l_str = torque_str(3:semis(1)-1);
        r_str = torque_str(semis(1)+3:semis(2)-1);   
        l_int = str2double(l_str);
        r_int = str2double(r_str);
        torques = [l_int r_int];

        torques = fliplr(torques);
        torques(2) = -torques(2);

    else

        torques = [0 0];

    end
    
    torques(torques > 250) = 250;
    torques(torques < -250) = -250;

    torque_data(ntuple, :) = torques;
    
end

