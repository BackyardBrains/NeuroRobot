
actions = zeros(ntuples, 1);
disp('getting actions')

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end

    torques = torque_data(ntuple, :);
    mses = zeros(size(cactions, 1), 1);
    for ii = 1:size(cactions, 1)
        mses(ii, 1) = immse(torques, cactions(ii,:));
    end

    [~, ind] = min(mses);
    actions(ntuple) = ind;

end

