states = zeros(ntuples, 1);
actions = zeros(ntuples, 1);
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/100))
        disp(num2str(ntuple/ntuples))
    end
    tuples_fname = horzcat(tuples_dir(ntuple).folder, '\', tuples_dir(ntuple).name);
    load(tuples_fname)
    states(ntuple) = tuple(1);
    actions(ntuple) = tuple(2);
end