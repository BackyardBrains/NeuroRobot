
torque_data = zeros(ntuples, 2);
disp(horzcat('getting ', num2str(ntuples), ' torques'))
% xtuples = randsample(ntuples, ntuples);
for ntuple = 1:ntuples

%     ntuple = xtuples(xtuple); 
    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end

    torque_fname = horzcat(torque_dir(ntuple).folder, '\', torque_dir(ntuple).name);
    load(torque_fname)
%     torques = [250 - round(rand * 500) 250 - round(rand * 500)];
    torques(torques > 250) = 250;
    torques(torques < -250) = -250;

%     if rand < 0.5
%         torques = [0 0];
%     end
    torque_data(ntuple, :) = torques;

end



save('torque_data', 'torque_data')

