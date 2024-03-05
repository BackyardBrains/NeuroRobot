
disp('Getting torques...')
if get_torques
    torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));
    ntorques = size(torque_dir, 1);
    torque_data = zeros(ntuples, 2);
    for ntuple = 1:ntuples
        if ~rem(ntuple, round(ntuples/10))
            disp(horzcat('done = ', num2str(round((100 * (ntuple/ntuples)))), '%'))
        end
        torque_fname = horzcat(torque_dir(ntuple).folder, '\', torque_dir(ntuple).name);
        load(torque_fname)
        torques(torques > 250) = 250;
        torques(torques < -250) = -250;
        torque_data(ntuple, :) = fliplr(torques); %% !!!!! FIX (240304)
    end
    save(strcat(nets_dir_name, state_net_name, '-torque_data'), 'torque_data')
else
    load(strcat(nets_dir_name, state_net_name, '-torque_data'))
end
